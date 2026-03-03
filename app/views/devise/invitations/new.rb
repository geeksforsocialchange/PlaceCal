# frozen_string_literal: true

class Views::Devise::Invitations::New < Views::Devise::Base
  def view_template
    h2 { t('devise.invitations.new.header') }

    simple_form_for(resource, as: resource_name,
                              url: helpers.invitation_path(resource_name),
                              html: { method: :post }) do |form|
      raw form.error_notification

      resource.class.invite_key_fields.each do |field|
        div(class: 'form-inputs') do
          raw form.input(field)
        end
      end

      div(class: 'form-actions') do
        raw form.button(:submit, t('devise.invitations.new.submit_button'))
      end
    end
  end
end
