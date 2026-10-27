# frozen_string_literal: true

class Views::Devise::Passwords::New < Views::Devise::Base
  def view_template
    content_for(:title) { t('devise.passwords.new.title') }

    Directory::PageHero(
      title: t('devise.passwords.new.title'),
      kicker: t('devise.shared.kicker'),
      breadcrumb_label: t('devise.passwords.new.breadcrumb')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        p(class: 'mb-6') { t('devise.passwords.new.intro') }

        form_for(resource, as: resource_name,
                           url: password_path(resource_name),
                           html: { method: :post, class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          div do
            render_label(form, :email)
            render_input(form, :email, type: 'email', value: resource.email, autofocus: true, autocomplete: 'email')
          end

          div { UI::Button(variant: :dark, type: 'submit') { t('devise.passwords.new.submit') } }
        end

        div(class: 'mt-6') do
          render_shared_links
        end
      end
    end
  end
end
