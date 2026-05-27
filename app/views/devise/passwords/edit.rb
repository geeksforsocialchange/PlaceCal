# frozen_string_literal: true

class Views::Devise::Passwords::Edit < Views::Devise::Base
  def view_template
    content_for(:title) { 'Change your password' }

    Directory::PageHero(
      title: 'Change your password',
      kicker: 'Account',
      breadcrumb_label: 'Reset password'
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        form_for(resource, as: resource_name,
                           url: password_path(resource_name),
                           html: { method: :put, class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          render_error_messages

          raw form.hidden_field(:reset_password_token)

          div do
            label(for: 'user_password', class: 'allcaps-label text-tertiary mb-1 block') do
              plain 'New password'
            end
            min_length = resource.class.password_length.min
            p(class: 'text-xs text-tertiary mb-1') { "(#{min_length} characters minimum)" } if min_length
            raw form.password_field(:password, autofocus: true, autocomplete: 'off', class: input_class)
          end

          div do
            label(for: 'user_password_confirmation', class: 'allcaps-label text-tertiary mb-1 block') do
              plain 'Confirm new password'
            end
            raw form.password_field(:password_confirmation, autocomplete: 'off', class: input_class)
          end

          div do
            raw form.submit('Change my password', class: submit_class)
          end
        end

        div(class: 'mt-6') do
          render_shared_links
        end
      end
    end
  end
end
