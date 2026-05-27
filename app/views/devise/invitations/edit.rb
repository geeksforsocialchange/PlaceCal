# frozen_string_literal: true

class Views::Devise::Invitations::Edit < Views::Devise::Base
  def view_template
    content_for(:title) { t('devise.invitations.edit.header') }

    Directory::PageHero(
      title: t('devise.invitations.edit.header'),
      kicker: 'Account',
      breadcrumb_label: 'Accept invitation'
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        render_error_messages

        form_for(resource, as: resource_name,
                           url: invitation_path(resource_name),
                           html: { method: :put, class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          raw form.hidden_field(:invitation_token)

          div do
            label(for: 'user_password', class: 'allcaps-label text-tertiary mb-1 block') { 'New password' }
            raw form.password_field(:password, class: input_class)
          end

          div do
            label(for: 'user_password_confirmation', class: 'allcaps-label text-tertiary mb-1 block') do
              plain 'Repeat password'
            end
            raw form.password_field(:password_confirmation, class: input_class)
          end

          div do
            raw form.submit('Set password', class: submit_class)
          end
        end
      end
    end
  end
end
