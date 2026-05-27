# frozen_string_literal: true

class Views::Devise::Base < Views::Base
  register_output_helper :form_for
  register_output_helper :simple_form_for

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

    div(class: 'rounded-card bg-secondary px-4 py-3 mb-4') do
      h2(class: 'font-bold text-sm text-foreground mb-1') do
        plain "#{resource.errors.count} error(s) prevented this form from being saved:"
      end
      ul(class: 'list-disc pl-5 text-sm text-foreground') do
        resource.errors.full_messages.each { |msg| li { msg } }
      end
    end
  end

  def render_shared_links
    div(class: 'flex flex-col gap-1 text-sm') do
      if controller_name != 'sessions'
        a(href: new_session_path(resource_name),
          class: 'text-foreground underline hover:decoration-primary') { 'Log in' }
      end

      if devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations'
        a(href: new_password_path(resource_name),
          class: 'text-foreground underline hover:decoration-primary') { 'Forgot your password?' }
      end
    end
  end

  def input_class
    'w-full border-2 border-rules rounded-card px-4 py-2 text-sm bg-background text-foreground outline-none focus:border-foreground transition-colors'
  end

  def submit_class
    'bg-foreground text-background rounded-full px-6 py-3 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors'
  end
end
