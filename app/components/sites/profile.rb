# frozen_string_literal: true

class Components::Sites::Profile < Components::Base
  include Phlex::Rails::Helpers::MailTo

  theme_scope :profile,
              parts: { root: 'One person\'s profile card.' },
              tokens: %i[--color-background --color-foreground --color-primary --radius-card]

  prop :user, _Interface(:email)  # User model or test double

  def view_template
    div(**part(:root, class: 'bg-background rounded-card mb-4 py-2 grid gap-x-4 md:grid-cols-avatar')) do
      div(class: 'md:col-span-2') do
        UI::RuledHeading(level: 3, caps: true, tone: :secondary, size: :sm, spacing: :card, class: 'text-center') { t('components.profile.heading') }
      end
      div(class: 'md:mt-2 md:mx-4') do
        image_tag(@user.avatar.retina.url, class: 'rounded-full max-w-27') if @user.avatar.retina.url
      end
      div(class: 'md:text-left') do
        p { strong { @user.full_name } }
        p do
          if @user.phone&.length&.positive?
            plain t('components.profile.call_on')
            whitespace
            strong { @user.phone }
            br
            plain t('components.profile.or_email')
          else
            plain t('components.profile.email')
          end
          whitespace
          strong { mail_to(@user.email) }
        end
      end
    end
  end
end
