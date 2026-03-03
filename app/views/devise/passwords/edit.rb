# frozen_string_literal: true

class Views::Devise::Passwords::Edit < Views::Devise::Base
  def view_template
    article(class: 'home margin') do
      div(class: 'card card--plainer') do
        h1(class: 'center fc-primary') { 'Change your password' }

        div(class: 'centre form--login') do
          form_for(resource, as: resource_name,
                             url: helpers.password_path(resource_name),
                             html: { method: :put, class: 'form', data: { turbo: 'false' } }) do |form|
            render_error_messages

            raw form.hidden_field(:reset_password_token)

            div(class: 'form__field') do
              raw form.label(:password, 'New password')
              min_length = resource.class.password_length.min
              if min_length
                whitespace
                em { "(#{min_length} characters minimum)" }
                br
              end
              raw form.password_field(:password, autofocus: true, autocomplete: 'off')
            end

            div(class: 'form__field') do
              raw form.label(:password_confirmation, 'Confirm new password')
              raw form.password_field(:password_confirmation, autocomplete: 'off')
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
