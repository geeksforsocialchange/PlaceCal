# frozen_string_literal: true

class Views::Admin::Partners::FormTabContact < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    partner = form.object

    div(class: 'space-y-6') do
      render_online_presence
      div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
        render_public_contact
        render_partnership_contact(partner)
      end
    end
  end

  private

  def render_online_presence
    FormCard(
      icon: :desktop,
      title: t('admin.sections.online_presence'),
      description: t('admin.partners.sections.online_presence_description')
    ) do
      fieldset(class: 'fieldset') do
        label(for: form.field_id(:url), class: 'fieldset-legend') { attr_label(:partner, :website) }
        raw form.input_field(:url, class: 'input input-bordered w-full bg-base-100',
                                   placeholder: t('admin.partners.fields.website_placeholder'),
                                   'data-validate-url': 'true',
                                   'data-validate-url-message': t('admin.hints.url_validation'))
      end
      SocialLinksField(form:)
    end
  end

  def render_public_contact
    FormCard(
      icon: :website,
      title: t('admin.sections.public_contact'),
      description: t('admin.hints.shown_publicly')
    ) do
      fieldset(class: 'fieldset') do
        label(for: form.field_id(:public_name), class: 'fieldset-legend') { attr_label(:partner, :name) }
        raw form.input_field(:public_name, class: 'input input-bordered w-full bg-base-100')
      end
      fieldset(class: 'fieldset') do
        label(for: form.field_id(:public_email), class: 'fieldset-legend') { attr_label(:partner, :email) }
        raw form.input_field(:public_email, class: 'input input-bordered w-full bg-base-100',
                                            'data-validate-email': 'true',
                                            'data-validate-email-message': t('admin.hints.email_validation'))
      end
      fieldset(class: 'fieldset') do
        label(for: form.field_id(:public_phone), class: 'fieldset-legend') { attr_label(:partner, :phone) }
        raw form.input_field(:public_phone, class: 'input input-bordered w-full bg-base-100')
      end
    end
  end

  def render_partnership_contact(partner)
    FormCard(
      icon: :partnership,
      title: t('admin.partners.sections.partnership_contact'),
      description: t('admin.partners.sections.partnership_contact_description')
    ) do
      fieldset(class: 'fieldset') do
        label(for: form.field_id(:partner_name), class: 'fieldset-legend') { attr_label(:partner, :name) }
        raw form.input_field(:partner_name,
                             class: 'input input-bordered w-full bg-base-100 placeholder:text-gray-400',
                             placeholder: partner.public_name)
      end
      fieldset(class: 'fieldset') do
        label(for: form.field_id(:partner_email), class: 'fieldset-legend') { attr_label(:partner, :email) }
        raw form.input_field(:partner_email,
                             class: 'input input-bordered w-full bg-base-100 placeholder:text-gray-400',
                             placeholder: partner.public_email,
                             'data-validate-email': 'true',
                             'data-validate-email-message': t('admin.hints.email_validation'))
      end
      fieldset(class: 'fieldset') do
        label(for: form.field_id(:partner_phone), class: 'fieldset-legend') { attr_label(:partner, :phone) }
        raw form.input_field(:partner_phone,
                             class: 'input input-bordered w-full bg-base-100 placeholder:text-gray-400',
                             placeholder: partner.public_phone)
      end
    end
  end
end
