# frozen_string_literal: true

class Views::Admin::Users::ProfileTabEmails < Views::Admin::Base
  include Phlex::Rails::Helpers::CheckBoxTag
  include Phlex::Rails::Helpers::HiddenFieldTag

  def view_template
    div(class: 'max-w-2xl space-y-4') do
      p(class: 'text-gray-600') { t('admin.users.profile.emails.intro') }

      EmailList.all.each { |list| render_list(list) }

      p(class: 'text-sm text-gray-500') { t('admin.users.profile.emails.essential_note') }
    end
  end

  private

  def render_list(list)
    div(class: 'fieldset') do
      label(class: 'flex items-start gap-3 cursor-pointer') do
        # Hidden field first so the checkbox value wins when checked; every
        # list always submits an explicit value
        raw hidden_field_tag("user[email_subscriptions][#{list.key}]", '0', id: nil)
        raw check_box_tag("user[email_subscriptions][#{list.key}]", '1',
                          EmailSubscription.subscribed?(current_user, list.key),
                          id: "user_email_subscriptions_#{list.key}",
                          class: 'checkbox checkbox-sm mt-1')
        span do
          span(class: 'block font-medium') { list.name }
          span(class: 'block text-sm text-gray-500') { list.description }
        end
      end
    end
  end
end
