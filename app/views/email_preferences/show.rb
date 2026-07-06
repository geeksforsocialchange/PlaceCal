# frozen_string_literal: true

class Views::EmailPreferences::Show < Views::Base
  include Phlex::Rails::Helpers::CheckBoxTag
  include Phlex::Rails::Helpers::SubmitTag

  prop :user, User, reader: :private
  prop :token, String, reader: :private

  def view_template
    content_for(:title) { t('email_preferences.show.title') }

    Directory::PageHero(
      title: t('email_preferences.show.title'),
      breadcrumb_label: t('email_preferences.show.title')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose-lg) mx-auto') do
        render_flash_messages
        p(class: 'mb-6') { t('email_preferences.show.intro', email: user.email) }
        render_form
        p(class: 'text-sm text-tertiary mt-6') { t('email_preferences.show.essential_note') }
      end
    end
  end

  private

  def render_flash_messages
    return unless view_context.flash.any?

    div(class: 'mb-4') do
      view_context.flash.each do |_key, value|
        div(class: 'rounded-card px-4 py-3 text-sm font-bold bg-primary text-foreground') { value }
      end
    end
  end

  def render_form
    form_tag(email_preferences_path, method: :patch, class: 'space-y-4') do
      raw hidden_field_tag(:token, token)
      EmailList.all.each { |list| render_list(list) }
      raw submit_tag(t('email_preferences.show.save'),
                     class: 'bg-foreground text-background rounded-full px-6 py-3 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors')
    end
  end

  def render_list(list)
    div(class: 'bg-home-background-3 rounded-card p-4') do
      div(class: 'flex items-start gap-3') do
        # Unchecked checkboxes are not submitted; the hidden field pairs with
        # each box (before it, so the box's value wins when checked) so the
        # controller always receives an explicit value per list
        raw hidden_field_tag("email_subscriptions[#{list.key}]", '0', id: nil)
        raw check_box_tag("email_subscriptions[#{list.key}]", '1',
                          EmailSubscription.subscribed?(user, list.key),
                          id: "email_subscriptions_#{list.key}",
                          class: 'w-4 h-4 mt-1 accent-primary')
        label(for: "email_subscriptions_#{list.key}", class: 'cursor-pointer') do
          p(class: 'font-bold text-sm text-foreground') { list.name }
          p(class: 'text-sm text-tertiary') { list.description }
        end
      end
    end
  end
end
