# frozen_string_literal: true

class Views::Admin::Users::FormTabPersonal < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'grid grid-cols-1 lg:grid-cols-3 gap-6') do
      div(class: 'lg:col-span-2 space-y-4') do
        div(class: 'grid grid-cols-2 gap-4') do
          fieldset(class: 'fieldset') do
            raw form.label(:first_name, attr_label(:user, :first_name), class: 'fieldset-legend')
            raw form.input_field(:first_name, class: 'input input-bordered w-full')
          end

          fieldset(class: 'fieldset') do
            raw form.label(:last_name, attr_label(:user, :last_name), class: 'fieldset-legend')
            raw form.input_field(:last_name, class: 'input input-bordered w-full')
          end
        end

        fieldset(class: 'fieldset') do
          raw form.label(:email, class: 'fieldset-legend') {
            "#{attr_label(:user, :email)} " \
            "<span class=\"text-error\">#{t('admin.labels.required')}</span>".html_safe
          }
          raw form.input_field(:email, class: 'input input-bordered w-full')
        end

        fieldset(class: 'fieldset') do
          raw form.label(:phone, attr_label(:user, :phone), class: 'fieldset-legend')
          raw form.input_field(:phone, class: 'input input-bordered w-full')
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
