# frozen_string_literal: true

class Views::Admin::Calendars::FormTabContact < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    SectionHeader(
      title: t('admin.calendars.tabs.contact'),
      description: t('admin.calendars.sections.contact_description')
    ) do |c|
      c.with_icon { raw icon(:phone, size: '5') }
    end

    div(class: 'max-w-xl') do
      FormCard(icon: :phone, title: t('admin.sections.public_contact')) do
        render_contact_name
        render_contact_email
        render_contact_phone
      end
    end
  end

  private

  def render_contact_name
    Field(for: form.field_id(:public_contact_name), label: attr_label(:calendar, :public_contact_name)) do
      raw form.input_field(:public_contact_name, class: 'input input-bordered input-sm w-full bg-base-100')
    end
  end

  def render_contact_email
    Field(for: form.field_id(:public_contact_email), label: attr_label(:calendar, :public_contact_email)) do
      raw form.input_field(:public_contact_email, class: 'input input-bordered input-sm w-full bg-base-100',
                                                  'data-validate-email': 'true',
                                                  'data-validate-email-message': t('admin.hints.email_validation'))
    end
  end

  def render_contact_phone
    Field(for: form.field_id(:public_contact_phone), label: attr_label(:calendar, :public_contact_phone)) do
      raw form.input_field(:public_contact_phone, class: 'input input-bordered input-sm w-full bg-base-100')
    end
  end
end
