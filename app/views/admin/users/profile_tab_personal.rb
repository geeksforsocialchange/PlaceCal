# frozen_string_literal: true

class Views::Admin::Users::ProfileTabPersonal < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'grid grid-cols-1 lg:grid-cols-3 gap-6') do
      div(class: 'lg:col-span-2 space-y-4') do
        div(class: 'grid grid-cols-2 gap-4') do
          div(class: 'fieldset') do
            label(for: 'user_first_name', class: 'fieldset-legend') { attr_label(:user, :first_name) }
            raw form.input_field(:first_name, class: 'input input-bordered w-full', id: 'user_first_name')
          end

          div(class: 'fieldset') do
            label(for: 'user_last_name', class: 'fieldset-legend') { attr_label(:user, :last_name) }
            raw form.input_field(:last_name, class: 'input input-bordered w-full', id: 'user_last_name')
          end
        end

        div(class: 'fieldset') do
          label(for: 'user_email', class: 'fieldset-legend') { attr_label(:user, :email) }
          raw form.input_field(:email, class: 'input input-bordered w-full', disabled: true, id: 'user_email')
          p(class: 'fieldset-label') { t('admin.users.profile.email_change_hint') }
        end

        div(class: 'fieldset') do
          label(for: 'user_phone', class: 'fieldset-legend') { attr_label(:user, :phone) }
          raw form.input_field(:phone, class: 'input input-bordered w-full', id: 'user_phone')
        end
      end

      render Components::Admin::ImageUpload.new(
        form: form,
        attribute: :avatar,
        rounded: 'rounded-xl'
      )
    end
  end
end
