# frozen_string_literal: true

class Views::Devise::Sessions::New < Views::Devise::Base
  def view_template
    content_for(:title) { 'Log in' }

    Directory::PageHero(
      title: 'Log in',
      kicker: 'Account',
      breadcrumb_label: 'Log in'
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        form_for(resource, as: resource_name,
                           url: session_path(resource_name),
                           html: { class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          div do
            label(for: 'user_email', class: 'allcaps-label text-tertiary mb-1 block') { 'Email' }
            raw form.email_field(:email, autofocus: true, class: input_class)
          end

          div do
            label(for: 'user_password', class: 'allcaps-label text-tertiary mb-1 block') { 'Password' }
            raw form.password_field(:password, autocomplete: 'off', class: input_class)
          end

          if devise_mapping.rememberable?
            div(class: 'flex items-center gap-2') do
              raw form.check_box(:remember_me, class: 'w-4 h-4 accent-primary')
              label(for: 'user_remember_me', class: 'text-sm text-foreground cursor-pointer') { 'Remember me' }
            end
          end

          div do
            raw form.submit('Log in', class: submit_class)
          end

          render_shared_links
        end
      end
    end
  end
end
