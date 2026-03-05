# frozen_string_literal: true

class Views::Devise::Passwords::New < Views::Devise::Base
  def view_template
    article(class: 'home margin') do
      div(class: 'card card--plainer') do
        h1(class: 'center fc-primary') { 'Forgot your password?' }
        p(class: 'center') do
          plain 'Enter the email address associated with your PlaceCal account and we will send you an email with password reset instructions.'
        end
        br

        div(class: 'centre form--login') do
          simple_form_for(resource,
                          as: resource_name,
                          url: password_path(resource_name),
                          html: { method: :post, class: 'form', data: { turbo: 'false' } }) do |form|
            div(class: 'form__field') do
              raw form.input(:email, autofocus: true)
            end
            br

            div(class: 'actions') do
              raw form.submit('Submit', class: 'btn btn--big btn--home-3')
            end
          end

          br
        end
      end
    end
  end
end
