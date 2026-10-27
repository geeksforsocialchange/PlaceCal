# frozen_string_literal: true

class Views::Devise::Invitations::Edit < Views::Devise::Base
  def view_template
    content_for(:title) { t('devise.invitations.edit.header') }

    Directory::PageHero(
      title: t('devise.invitations.edit.header'),
      kicker: t('devise.shared.kicker'),
      breadcrumb_label: t('devise.invitations.edit.breadcrumb')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        render_error_messages

        form_for(resource, as: resource_name,
                           url: invitation_path(resource_name),
                           html: { method: :put, class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          raw form.hidden_field(:invitation_token)

          render_field(form, :password, label: t('devise.invitations.edit.new_password'), type: 'password', reveal: true, autocomplete: 'new-password')

          render_field(form, :password_confirmation, label: t('devise.invitations.edit.repeat_password'), type: 'password', reveal: true, autocomplete: 'new-password')

          div { UI::Button(variant: :dark, type: 'submit') { t('devise.invitations.edit.submit_button') } }
        end
      end
    end
  end
end
