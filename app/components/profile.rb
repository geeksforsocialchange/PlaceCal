# frozen_string_literal: true

class Components::Profile < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :user, _Any

  def view_template
    div(class: 'profile') do
      div(class: 'profile__title') do
        h3(class: 'h2--alt udl') { 'Your local contact' }
      end
      div(class: 'profile__avatar') do
        image_tag(@user.avatar.retina.url) if @user.avatar.retina.url
      end
      div(class: 'profile__details') do
        p { strong { @user.full_name } }
        p do
          if @user.phone&.length&.positive?
            plain 'Call on '
            strong { @user.phone }
            br
            plain 'Or send an email to '
          else
            plain 'Email '
          end
          strong { mail_to(@user.email) }
        end
      end
    end
  end
end
