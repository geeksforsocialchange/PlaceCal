# frozen_string_literal: true

class Views::Devise::Passwords::Edit < Views::Devise::Base
  def view_template
    article(class: 'home margin') do
      div(class: 'card card--plainer') do
        h1(class: 'center fc-primary') { 'Change your password' }

        div(class: 'centre form--login') do
          simple_form_for(resource,
                          as: resource_name,
                          url: password_path(resource_name),
                          html: { method: :put, class: 'form', data: { turbo: 'false' } }) do |form|
            render_error_messages

            raw form.hidden_field(:reset_password_token)

            div(class: 'form__field') do
              input_html = { autofocus: true }
              if min_length
                input_html[:minlength] = min_length
                input_html[:hint] = "#{min_length} characters minimum"
              end
              raw form.input(:password, as: :password_custom, input_html: input_html)
            end

            div(class: 'form__field') do
              raw form.input(:password_confirmation, as: :password_custom, label: 'Confirm new password')
            end
            br

            div(class: 'actions') do
              raw form.submit('Change my password', class: 'btn btn--big btn--home-3')
            end
          end

          br
        end
      end
    end
  end
end
