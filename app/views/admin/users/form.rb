# frozen_string_literal: true

class Views::Admin::Users::Form < Views::Admin::Base
  prop :form, _Any, reader: :private
  prop :user, _Any, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Error.new(form.object))

    div(class: 'tabs tabs-lift') do
      render Components::Admin::TabPanel.new(
        name: 'user_tabs', label: "\u{1F464} Personal Details", hash: 'personal',
        controller_name: 'form-tabs', checked: true
      ) { raw view_context.render('admin/users/form_tab_personal', f: form) }

      render Components::Admin::TabPanel.new(
        name: 'user_tabs', label: "\u{1F511} Permissions", hash: 'permissions',
        controller_name: 'form-tabs'
      ) { raw view_context.render('admin/users/form_tab_roles', f: form) }

      if helpers.policy(user).permitted_attributes_for_update.include?(:role) || helpers.policy(user).destroy?
        div(class: 'tab flex-1 cursor-default')

        render Components::Admin::TabPanel.new(
          name: 'user_tabs', label: "\u{2699}\u{FE0F} Settings", hash: 'settings',
          controller_name: 'form-tabs'
        ) { raw view_context.render('admin/users/form_tab_settings', f: form) }
      end
    end
  end
end
