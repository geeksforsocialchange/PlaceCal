# frozen_string_literal: true

class Views::Devise::Base < Views::Base
  register_output_helper :form_for
  register_output_helper :simple_form_for

  private

  def resource
    helpers.resource
  end

  def resource_name
    helpers.resource_name
  end

  def devise_mapping
    helpers.devise_mapping
  end

  def render_error_messages
    return if resource.errors.empty?

    div(id: 'error_explanation') do
      h2 { "#{resource.errors.count} error(s) prevented this form from being saved:" }
      ul do
        resource.errors.full_messages.each { |msg| li { msg } }
      end
    end
  end

  def render_shared_links
    controller = helpers.controller_name

    if controller != 'sessions'
      link_to('Log in', helpers.new_session_path(resource_name))
      br
    end

    return unless devise_mapping.recoverable? && controller != 'passwords' && controller != 'registrations'

    link_to('Forgot your password?', helpers.new_password_path(resource_name))
    br
  end
end
