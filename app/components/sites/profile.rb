# frozen_string_literal: true

class Components::Sites::Profile < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :user, _Interface(:email)  # User model or test double

  def view_template
    div(class: 'profile bg-background rounded-card mb-4 py-2 grid gap-x-4 md:grid-cols-avatar') do
      div(class: 'profile__title md:col-span-2') do
        h3(class: 'allcaps text-center text-base inline-block pb-2 border-b-3 border-secondary mb-6') { t('components.profile.heading') }
      end
      div(class: 'profile__avatar md:mt-2 md:mx-4') do
        image_tag(@user.avatar.retina.url, class: 'rounded-full max-w-27') if @user.avatar.retina.url
      end
      div(class: 'profile__details md:text-left') do
        p { strong { @user.full_name } }
        p do
          if @user.phone&.length&.positive?
            plain "#{t('components.profile.call_on')} "
            strong { @user.phone }
            br
            plain "#{t('components.profile.or_email')} "
          else
            plain "#{t('components.profile.email')} "
          end
          strong { mail_to(@user.email) }
        end
      end
    end
  end
end
