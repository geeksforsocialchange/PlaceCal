# frozen_string_literal: true

class Views::Devise::Passwords::New < Views::Devise::Base
  def view_template
    content_for(:title) { 'Forgot your password?' }

    Directory::PageHero(
      title: 'Forgot your password?',
      kicker: 'Account',
      breadcrumb_label: 'Forgot password'
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        p(class: 'text-sm text-tertiary mb-6') do
          plain 'Enter the email address associated with your PlaceCal account and we will send you an email with password reset instructions.'
        end

        form_for(resource, as: resource_name,
                           url: password_path(resource_name),
                           html: { method: :post, class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          div do
            label(for: 'user_email', class: 'allcaps-label text-tertiary mb-1 block') { 'Email' }
            raw form.email_field(:email, autofocus: true, class: input_class)
          end

          div do
            raw form.submit('Submit', class: submit_class)
          end
        end

        div(class: 'mt-6') do
          render_shared_links
        end
      end
    end
  end
end
