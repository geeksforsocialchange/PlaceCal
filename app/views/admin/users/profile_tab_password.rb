# frozen_string_literal: true

class Views::Admin::Users::ProfileTabPassword < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    div(class: 'space-y-6') do
      div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
        div(class: 'card-body p-6') do
          SectionHeader(
            title: t('admin.users.profile.password_title'),
            description: t('admin.users.profile.password_description'),
            margin: 4
          )

          div(class: 'w-full lg:w-2/3 space-y-4') do
            render_new_password_field
            render_confirm_password_field
            render_current_password_field
          end
        end
      end
    end
  end

  private

  def render_new_password_field
    div(class: 'fieldset') do
      label(for: 'user_password', class: 'fieldset-legend') { t('admin.users.profile.new_password') }
      raw form.input_field(:password,
                           type: :password,
                           class: 'input input-bordered w-full',
                           autocomplete: 'new-password',
                           id: 'user_password',
                           data: {
                             validate_min: Devise.password_length.min,
                             validate_min_message: t('admin.validation.password_min', count: Devise.password_length.min)
                           })
    end
  end

  def render_confirm_password_field
    div(class: 'fieldset') do
      label(for: 'user_password_confirmation', class: 'fieldset-legend') { t('admin.users.profile.confirm_password') }
      raw form.input_field(:password_confirmation,
                           type: :password,
                           class: 'input input-bordered w-full',
                           autocomplete: 'new-password',
                           id: 'user_password_confirmation',
                           data: {
                             validate_confirm: 'user_password',
                             validate_confirm_message: t('admin.validation.password_mismatch')
                           })
    end
  end

  def render_current_password_field
    div(class: 'fieldset') do
      label(for: 'user_current_password', class: 'fieldset-legend') do
        plain t('admin.users.profile.current_password')
        whitespace
        span(class: 'text-error') { t('admin.labels.required') }
      end
      raw form.input_field(:current_password, type: :password,
                                              class: 'input input-bordered w-full',
                                              autocomplete: 'current-password',
                                              id: 'user_current_password')
      p(class: 'fieldset-label') { t('admin.users.profile.current_password_hint') }
    end
  end
end
