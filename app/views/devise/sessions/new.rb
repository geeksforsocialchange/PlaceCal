# frozen_string_literal: true

class Views::Devise::Sessions::New < Views::Devise::Base
  def view_template
    content_for(:title) { t('devise.sessions.new.title') }

    Directory::PageHero(
      title: t('devise.sessions.new.title'),
      kicker: t('devise.shared.kicker'),
      breadcrumb_label: t('devise.sessions.new.title')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose) mx-auto') do
        form_for(resource, as: resource_name,
                           url: session_path(resource_name),
                           html: { class: 'space-y-4', data: { turbo: 'false' } }) do |form|
          div do
            render_label(form, :email)
            render_input(form, :email, type: 'email', value: resource.email, autofocus: true, autocomplete: 'email')
          end

          div do
            render_label(form, :password)
            render_input(form, :password, type: 'password', autocomplete: 'current-password')
          end

          if devise_mapping.rememberable?
            div(class: 'flex items-center gap-2') do
              raw form.check_box(:remember_me, class: 'w-4 h-4 accent-primary')
              label(for: form.field_id(:remember_me), class: 'text-sm text-foreground cursor-pointer') do
                resource.class.human_attribute_name(:remember_me)
              end
            end
          end

          div { UI::Button(variant: :dark, type: 'submit') { t('devise.sessions.new.submit') } }

          render_shared_links
        end
      end
    end
  end
end
