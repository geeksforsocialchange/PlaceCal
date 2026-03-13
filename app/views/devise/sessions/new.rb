# frozen_string_literal: true

class Views::Devise::Sessions::New < Views::Devise::Base
  def view_template
    article(class: 'home mx-3 tp:mx-6') do
      div(class: 'card card--plainer') do
        h1(class: 'center fc-primary') { 'Log in' }

        div(class: 'centre form--login') do
          form_for(resource, as: resource_name,
                             url: session_path(resource_name),
                             html: { class: 'form' },
                             data: { turbo: 'false' }) do |form|
            div(class: 'form__field') do
              raw form.label(:email)
              raw form.email_field(:email, autofocus: true)
            end

            div(class: 'form__field') do
              raw form.label(:password)
              raw form.password_field(:password, autocomplete: 'off')
            end

            if devise_mapping.rememberable?
              div(class: 'form__field--remember') do
                raw form.label(:remember_me)
                raw form.check_box(:remember_me, class: 'round')
              end
            end

            div(class: 'devise') do
              render_shared_links
            end

            br

            div(class: 'actions') do
              raw form.submit('Log in', class: 'btn btn--big btn--home-3')
            end
          end
        end

        br
        br
      end
    end
  end
end
