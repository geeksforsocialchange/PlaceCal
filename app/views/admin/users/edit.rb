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
      div(class: 'text-sm text-gray-600') { "ID: #{user.id}" }
    end

    disabled_fields = helpers.policy(user).disabled_attributes_for_update
    displayable_fields = helpers.policy(user).permitted_attributes_for_update

    filtered_form_for(user,
                      method: :put,
                      url: helpers.admin_user_path(user),
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
end
