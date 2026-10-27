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

          div do
            render_label(form, :password, t('devise.invitations.edit.new_password'))
            render_input(form, :password, type: 'password', reveal: true, autocomplete: 'new-password')
          end

          div do
            render_label(form, :password_confirmation, t('devise.invitations.edit.repeat_password'))
            render_input(form, :password_confirmation, type: 'password', reveal: true, autocomplete: 'new-password')
          end

          div { UI::Button(variant: :dark, type: 'submit') { t('devise.invitations.edit.submit_button') } }
        end
      end
    end
  end
end
