# frozen_string_literal: true

require_relative 'auth_common'

class DeviseController
  # monkey patching devise so it can handle the new default behaviour in rails 7
  #   redirects

  original_redirect_to = instance_method(:redirect_to)
  define_method(:redirect_to) do |options, response_options = {}|
    if options.is_a?(Hash)
      options[:allow_other_host] = true unless options.key?(:allow_other_host)

    elsif response_options.is_a?(Hash)
      response_options[:allow_other_host] = true unless response_options.key?(:allow_other_host)
    end

    original_redirect_to
      .bind_call(self, options, response_options)
  end
end

class Users::SessionsController < Devise::SessionsController
  include Users::AuthCommon

  before_action :set_site
end
