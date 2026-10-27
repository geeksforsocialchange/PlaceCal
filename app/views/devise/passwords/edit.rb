# frozen_string_literal: true

class Views::Devise::Passwords::Edit < Views::Devise::Base
  def view_template
    content_for(:title) { t('devise.passwords.edit.title') }

    Directory::PageHero(
      title: t('devise.passwords.edit.title'),
      kicker: t('devise.shared.kicker'),
      breadcrumb_label: t('devise.passwords.edit.breadcrumb')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        form_for(resource, as: resource_name,
                           url: password_path(resource_name),
                           html: { method: :put, class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          render_error_messages

          raw form.hidden_field(:reset_password_token)

          div do
            render_label(form, :password, t('devise.passwords.edit.new_password'))
            min_length = resource.class.password_length.min
            p(class: 'text-sm text-tertiary mb-1') { t('devise.passwords.edit.minimum_length', count: min_length) } if min_length
            render_input(form, :password, type: 'password', reveal: true, autofocus: true, autocomplete: 'new-password')
          end

          div do
            render_label(form, :password_confirmation, t('devise.passwords.edit.confirm_new_password'))
            render_input(form, :password_confirmation, type: 'password', reveal: true, autocomplete: 'new-password')
          end

          div { UI::Button(variant: :dark, type: 'submit') { t('devise.passwords.edit.submit') } }
        end

        div(class: 'mt-6') do
          render_shared_links
        end
      end
    end
  end
end
