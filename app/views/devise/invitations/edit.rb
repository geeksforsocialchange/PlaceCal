# frozen_string_literal: true

class Views::Devise::Invitations::Edit < Views::Devise::Base
  def view_template
    article(class: 'home mx-3 tp:mx-6') do
      div(class: 'card card--plainer') do
        h1(class: 'center fc-primary') { t('devise.invitations.edit.header') }

        render Components::Admin::Error.new(resource)

        div(class: 'centre form--login') do
          form_for(resource, as: resource_name,
                             url: invitation_path(resource_name),
                             html: { method: :put, class: 'form', data: { turbo: 'false' } }) do |form|
            raw form.hidden_field(:invitation_token)

            div(class: 'form__field') do
              raw form.label(:password, 'New password')
              raw form.password_field(:password)

              raw form.label(:password_confirmation, 'Repeat password')
              raw form.password_field(:password_confirmation)
            end

            div(class: 'form__field') do
              raw form.submit('Set password', class: 'btn btn--big btn--home-3')
            end
          end
        end
      end
    end
  end
end
