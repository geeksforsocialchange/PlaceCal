# frozen_string_literal: true

class Components::Profile < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :user, _Interface(:email)  # User model or test double

  def view_template
    div(class: 'bg-base-background rounded-lg mb-4 py-2 grid gap-x-4 grid-cols-1 tp:grid-cols-[150px_auto] [&_h3]:border-b-base-secondary [&_h3]:mb-6') do
      div(class: 'tp:col-span-2') do
        h3(class: 'h2--alt udl') { 'Your local contact' }
      end
      div(class: 'tp:mt-2 tp:mx-4 [&_img]:rounded-full [&_img]:max-w-[120px]') do
        image_tag(@user.avatar.retina.url) if @user.avatar.retina.url
      end
      div(class: 'tp:text-left tp:align-top') do
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
