# frozen_string_literal: true

class Views::Admin::Users::Form < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private
  prop :user, User, reader: :private

  def view_template
    Error(form.object)

    div(class: 'tabs tabs-lift') do
      TabPanel(
        name: 'user_tabs', label: "\u{1F464} Personal Details", hash: 'personal',
        controller_name: 'form-tabs', checked: true
      ) { render Views::Admin::Users::FormTabPersonal.new(form: form) }

      TabPanel(
        name: 'user_tabs', label: "\u{1F511} Permissions", hash: 'permissions',
        controller_name: 'form-tabs'
      ) { render Views::Admin::Users::FormTabRoles.new(form: form) }

      if helpers.policy(user).permitted_attributes_for_update.include?(:role) || helpers.policy(user).destroy?
        div(class: 'tab flex-1 cursor-default')

        TabPanel(
          name: 'user_tabs', label: "\u{2699}\u{FE0F} Settings", hash: 'settings',
          controller_name: 'form-tabs'
        ) { render Views::Admin::Users::FormTabSettings.new(form: form) }
      end
    end
  end
end
