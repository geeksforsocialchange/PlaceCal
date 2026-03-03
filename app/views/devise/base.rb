# frozen_string_literal: true

class Views::Devise::Base < Views::Base
  register_output_helper :form_for
  register_output_helper :simple_form_for

  # Devise provides shortened route helpers (e.g. session_path instead of user_session_path)
  register_value_helper :session_path
  register_value_helper :password_path
  register_value_helper :invitation_path
  register_value_helper :new_session_path
  register_value_helper :new_password_path

  private

  def resource
    view_context.resource
  end

  def resource_name
    view_context.resource_name
  end

  def devise_mapping
    view_context.devise_mapping
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
    if controller_name != 'sessions'
      link_to('Log in', new_session_path(resource_name))
      br
    end

    return unless devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations'

    link_to('Forgot your password?', new_password_path(resource_name))
    br
  end
end
