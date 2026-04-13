# frozen_string_literal: true

class GraphqlController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :set_supporters
  skip_before_action :set_navigation

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { errors: [{ message: e.message }], data: nil }, status: :ok
  end

  rescue_from ActiveRecord::StatementInvalid do |e|
    raise e unless e.cause.is_a?(PG::InvalidTextRepresentation)

    render json: { errors: [{ message: 'Invalid query parameters' }], data: nil }, status: :ok
  end

  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
    }
    # Apply depth/complexity limits to regular queries but not introspection (__schema/__type),
    # which is inherently deep and complex.
    introspection = query&.include?('__schema')
    # Deepest legitimate query is 4 levels (e.g. event → address → geo → latitude)
    max_depth = introspection ? nil : 10
    # Highest real-world query scores ~1100 (articleConnection with all fields).
    # Trans Dimension queries score ~100 each.
    max_complexity = introspection ? nil : 1500

    result = PlaceCalSchema.execute(query, variables: variables, context: context,
                                           operation_name: operation_name,
                                           max_depth: max_depth,
                                           max_complexity: max_complexity)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  ensure
    Appsignal::Transaction.current.set_namespace('graphql')
    Appsignal::Transaction.current.set_action(operation_name || 'Unknown')
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: :internal_server_error
  end
end
