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

          render_field(form, :password, label: t('devise.passwords.edit.new_password'), hint: minimum_length_hint, type: 'password', reveal: true,
                                        autofocus: true, autocomplete: 'new-password')

          render_field(form, :password_confirmation, label: t('devise.passwords.edit.confirm_new_password'), type: 'password', reveal: true,
                                                     autocomplete: 'new-password')

          div { UI::Button(variant: :dark, type: 'submit') { t('devise.passwords.edit.submit') } }
        end

        div(class: 'mt-6') do
          render_shared_links
        end
      end
    end
  end

  private

  def minimum_length_hint
    min = resource.class.password_length.min
    t('devise.passwords.edit.minimum_length', count: min) if min
  end
end
