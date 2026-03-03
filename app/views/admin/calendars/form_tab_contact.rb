# frozen_string_literal: true

class Views::Admin::Calendars::FormTabContact < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/MethodLength
    render Components::Admin::SectionHeader.new(
      title: t('admin.calendars.tabs.contact'),
      description: t('admin.calendars.sections.contact_description')
    ) do |c|
      c.with_icon { raw icon(:phone, size: '5') }
    end

    div(class: 'max-w-xl') do
      render(Components::Admin::FormCard.new(icon: :phone, title: t('admin.sections.public_contact'))) do
        render_contact_name
        render_contact_email
        render_contact_phone
      end
    end
  end

  private

  def render_contact_name
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { attr_label(:calendar, :public_contact_name) }
      raw form.input_field(:public_contact_name, class: 'input input-bordered input-sm w-full bg-base-100')
    end
  end

  def render_contact_email
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { attr_label(:calendar, :public_contact_email) }
      raw form.input_field(:public_contact_email, class: 'input input-bordered input-sm w-full bg-base-100',
                                                  'data-validate-email': 'true',
                                                  'data-validate-email-message': t('admin.hints.email_validation'))
    end
  end

  def render_contact_phone
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { attr_label(:calendar, :public_contact_phone) }
      raw form.input_field(:public_contact_phone, class: 'input input-bordered input-sm w-full bg-base-100')
    end
  end
end
