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

    UI::Card(variant: :highlight, padding: :sm) do
      h2(class: 'font-bold text-sm mb-1') do
        plain t('errors.messages.not_saved', count: resource.errors.count, resource: resource.model_name.human.downcase)
      end
      ul(class: 'list-disc pl-5 text-sm') do
        resource.errors.full_messages.each { |msg| li { msg } }
      end
    end
  end

  def render_shared_links
    div(class: 'flex flex-col gap-1 text-sm') do
      if controller_name != 'sessions'
        a(href: new_session_path(resource_name),
          class: 'underline hover:decoration-primary') { t('devise.shared.links.log_in') }
      end

      if devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations'
        a(href: new_password_path(resource_name),
          class: 'underline hover:decoration-primary') { t('devise.shared.links.forgot_your_password') }
      end
    end
  end

  def render_field(form, attribute, type:, label: resource.class.human_attribute_name(attribute), hint: nil, **)
    UI::Field(label:, id: form.field_id(attribute), hint:) do |field|
      UI::Input(type:, name: form.field_name(attribute), id: form.field_id(attribute), aria: { describedby: field.hint_id }, **)
    end
  end
end
