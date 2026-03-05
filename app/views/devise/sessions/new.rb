# frozen_string_literal: true

class Views::Devise::Sessions::New < Views::Devise::Base
  register_output_helper :icon

  def view_template
    article(class: 'home margin') do
      div(class: 'card card--plainer') do
        h1(class: 'center fc-primary') { 'Log in' }

        div(class: 'centre form--login') do
          simple_form_for(resource,
                          as: resource_name,
                          url: session_path(resource_name),
                          html: { class: 'form' },
                          data: { turbo: 'false' }) do |form|
            div(class: 'form__field') do
              raw form.input(:email, autofocus: true)
            end

            div(class: 'form__field') do
              raw form.input(:password, as: :password_custom)
            end

            if devise_mapping.rememberable?
              div(class: 'form__checkbox form__field--remember') do
                raw form.check_box(:remember_me)
                label(for: 'user_remember_me') do
                  plain 'Remember me'
                  icon(:form_checkbox, size: nil)
                  icon(:form_checkbox_check, size: nil, css_class: 'checked text-base-primary')
                end
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
