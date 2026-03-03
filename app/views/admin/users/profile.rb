# frozen_string_literal: true

class Views::Admin::Users::Profile < Views::Admin::Base
  prop :current_user, User, reader: :private

  def view_template
    content_for(:title) { t('admin.users.profile.title') }

    div(class: 'mb-6') do
      h1(class: 'text-2xl font-semibold') { t('admin.users.profile.title') }
      p(class: 'text-gray-600 mt-1') { current_user.email }
    end

    simple_form_for(current_user,
                    as: :user,
                    method: :patch,
                    url: helpers.update_profile_admin_user_path(current_user),
                    html: { class: 'space-y-6', data: {
                      controller: 'form-tabs live-validation form-dirty',
                      'form-tabs-storage-key-value': 'profileTabAfterSave',
                      'form-dirty-tab-name-value': 'profile_tabs'
                    } }) do |form|
      Error(current_user)
      render_tabs(form)
      render_save_bar(form)
    end
  end

  private

  def render_tabs(form) # rubocop:disable Metrics/MethodLength
    div(class: 'tabs tabs-lift') do
      TabPanel(
        name: 'profile_tabs',
        label: "\u{1F464} #{t('admin.users.profile.tabs.personal')}",
        hash: 'personal',
        controller_name: 'form-tabs',
        checked: true
      ) do
        render Views::Admin::Users::ProfileTabPersonal.new(form: form)
      end

      TabPanel(
        name: 'profile_tabs',
        label: "\u{1F511} #{t('admin.users.profile.tabs.password')}",
        hash: 'password',
        controller_name: 'form-tabs'
      ) do
        render Views::Admin::Users::ProfileTabPassword.new(form: form)
      end

      TabPanel(
        name: 'profile_tabs',
        label: "\u{1F6E1}\u{FE0F} #{t('admin.users.profile.tabs.permissions')}",
        hash: 'permissions',
        controller_name: 'form-tabs'
      ) do
        render Views::Admin::Users::ProfileTabPermissions.new(form: form)
      end
    end
  end

  def render_save_bar(form)
    SaveBar(track_changes: true) do
      raw form.submit(t('admin.users.profile.save_button'),
                      class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange btn-disabled opacity-50 cursor-not-allowed',
                      disabled: true,
                      data: { 'form-dirty-target': 'submit' })
    end
  end
end
