# frozen_string_literal: true

class Views::Admin::Users::Edit < Views::Admin::Base
  prop :user, User, reader: :private

  def view_template
    content_for(:title) { "Edit User: #{user.full_name.presence || user.email}" }

    div(class: 'flex items-center justify-between mb-6') do
      div do
        h1(class: 'text-2xl font-semibold') { 'Edit User' }
        p(class: 'text-gray-600 mt-1') { user.full_name.presence || user.email }
      end
      div(class: 'flex items-center gap-4') do
        render_login_help_button
        div(class: 'text-sm text-gray-600') { "ID: #{user.id}" }
      end
    end

    disabled_fields = policy(user).disabled_attributes_for_update
    displayable_fields = policy(user).permitted_attributes_for_update

    filtered_form_for(user,
                      method: :put,
                      url: admin_user_path(user),
                      disabled: disabled_fields,
                      display_only: displayable_fields,
                      html: { data: { controller: 'form-tabs live-validation',
                                      'form-tabs-storage-key-value': 'userTabAfterSave' } }) do |form|
      render Views::Admin::Users::Form.new(form: form, user: user)
      SaveBar(
        multi_step: true,
        tab_name: 'user_tabs',
        settings_hash: 'settings',
        storage_key: 'userTabAfterSave'
      )
    end
  end

  private

  # Re-send invitation / password reset (#3256 phase 3). Lives outside the
  # main form because button_to renders its own form element.
  def render_login_help_button
    pending_invite = user.created_by_invite? && !user.invitation_accepted?
    label = pending_invite ? t('admin.users.send_login_help.resend_invitation') : t('admin.users.send_login_help.send_reset')

    button_to(label,
              send_login_help_admin_user_path(user),
              method: :post,
              class: 'btn btn-sm btn-outline',
              data: { turbo_confirm: t('admin.users.send_login_help.confirm', email: user.email) })
  end
end
