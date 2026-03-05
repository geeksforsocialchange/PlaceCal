# frozen_string_literal: true

class Views::Admin::Partners::New < Views::Admin::Base
  prop :partner, Partner, reader: :private

  def view_template
    content_for(:title) { 'New Partner' }

    div(data: { controller: 'partner-wizard',
                'partner-wizard-current-step-value': '1',
                'partner-wizard-total-steps-value': '6' }) do
      div(class: 'max-w-4xl mx-auto') do
        render_header
        render_steps_indicator
      end

      simple_form_for partner, html: { data: { partner_wizard_target: 'form' } } do |form|
        div(class: 'max-w-4xl mx-auto') do
          Error(partner)
          render_step_name(form)
          render_step_location(form)
          render_step_tags(form)
          render_step_contact(form)
          render_step_invite(form)
          render_step_confirm(form)
        end

        SaveBar(
          wizard: true,
          wizard_controller: 'partner-wizard',
          submit_label: 'Create Partner'
        )
      end
    end
  end

  private

  def render_header
    div(class: 'text-center mb-8') do
      h1(class: 'text-2xl font-bold text-base-content mb-2') { 'Create a New Partner' }
      p(class: 'text-gray-600') { "Let's get your partner organisation set up in PlaceCal" }
    end
  end

  def render_steps_indicator
    steps = %w[Name Location Tags Contact Invite Confirm]
    ul(class: 'steps steps-horizontal w-full mb-8 text-xs') do
      steps.each_with_index do |step_name, i|
        step_num = i + 1
        li(class: "step#{' step-primary' if step_num == 1}",
           data: { 'partner-wizard-target': 'stepIndicator', step: step_num.to_s }) do
          span(class: 'step-content') { step_name }
        end
      end
    end
  end

  def render_step_header(icon_name, title, description, icon_color: 'bg-placecal-orange/10', icon_text_color: 'text-placecal-orange')
    div(class: 'flex items-start gap-4 mb-6') do
      div(class: "shrink-0 w-12 h-12 rounded-xl #{icon_color} flex items-center justify-center") do
        raw icon(icon_name, size: '6', css_class: icon_text_color)
      end
      div do
        h2(class: 'card-title text-xl') { title }
        p(class: 'text-gray-600 text-sm mt-1') { description }
      end
    end
  end

  def wizard_card(step:, hidden: true, &)
    div(class: "card bg-base-100 shadow-lg border border-base-300#{' hidden' if hidden}",
        data: { 'partner-wizard-target': 'step', step: step.to_s }, &)
  end

  def render_step_name(form)
    wizard_card(step: 1, hidden: false) do
      div(class: 'card-body') do
        render_step_header(:partner, 'Name Your Partner',
                           'Enter the official name of the organisation. We\'ll check if it already exists.')
        render_name_field(form)
        render_summary_field(form)
        render_description_field(form)
      end
    end
  end

  def render_name_field(form)
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6') do
      legend(class: 'fieldset-legend text-base font-semibold') do
        plain 'Partner Name '
        span(class: 'text-error') { '*' }
      end
      raw form.input_field(:name,
                           class: 'input input-bordered input-lg w-full text-lg',
                           placeholder: 'e.g. Community Centre Name',
                           autocomplete: 'off',
                           'data-partner-wizard-target': 'nameInput',
                           'data-action': 'input->partner-wizard#checkName')
      p(class: 'text-sm text-red-700 mt-2', data: { 'partner-wizard-target': 'nameMinLengthHint' }) do
        plain 'Must be at least 5 characters long'
      end
      render_name_feedback
    end
  end

  def render_name_feedback
    div(class: 'mt-4 hidden', data: { 'partner-wizard-target': 'nameFeedback' }) do
      div(class: 'alert alert-warning text-sm hidden', data: { 'partner-wizard-target': 'exactMatch' }) do
        raw icon(:warning, size: '5', css_class: 'shrink-0')
        div do
          p(class: 'font-semibold') { 'A partner with this exact name already exists' }
          p(class: 'text-xs mt-1') { 'You may want to edit the existing partner instead.' }
        end
        a(href: '#', class: 'btn btn-sm btn-warning', data: { 'partner-wizard-target': 'exactMatchLink' }) { 'View Partner' }
      end
      div(class: 'hidden', data: { 'partner-wizard-target': 'similarSection' }) do
        p(class: 'text-sm font-medium text-base-content/70 mb-2 flex items-center gap-2') do
          raw icon(:info, size: '4')
          plain 'Partners with similar names:'
        end
        div(class: 'space-y-1', data: { 'partner-wizard-target': 'similarList' })
      end
      div(class: 'alert alert-success text-sm hidden', data: { 'partner-wizard-target': 'nameAvailable' }) do
        raw icon(:check_circle, size: '5', css_class: 'shrink-0')
        span { 'This name is available!' }
      end
    end
  end

  def render_summary_field(form)
    div(class: 'fieldset bg-base-200/50 rounded-xl p-6 mt-6',
        data: { controller: 'char-counter', 'char-counter-max-value': '200' }) do
      label(for: 'partner_summary', class: 'fieldset-legend text-base font-semibold') { attr_label(:partner, :summary) }
      raw form.input_field(:summary, as: :text,
                                     class: 'textarea textarea-bordered w-full bg-base-100 min-h-16',
                                     maxlength: 200, id: 'partner_summary',
                                     data: { controller: 'auto-expand', char_counter_target: 'input', action: 'input->char-counter#update' })
      div(class: 'flex items-center justify-between mt-2') do
        p(class: 'text-sm text-gray-600') { t('admin.partners.fields.summary_hint') }
        span(class: 'text-xs tabular-nums transition-colors', data: { 'char-counter-target': 'counter' }) { '0 / 200' }
      end
    end
  end

  def render_description_field(form)
    div(class: 'fieldset bg-base-200/50 rounded-xl p-6 mt-6') do
      label(for: 'partner_description', class: 'fieldset-legend text-base font-semibold') { attr_label(:partner, :description) }
      raw form.input_field(:description,
                           class: 'textarea textarea-bordered w-full bg-base-100 min-h-32',
                           id: 'partner_description', data: { controller: 'auto-expand' })
      p(class: 'text-sm text-gray-600 mt-2') { t('admin.partners.fields.description_hint') }
    end
  end

  def render_step_location(form)
    wizard_card(step: 2) do
      div(class: 'card-body') do
        render_step_header(:location, 'Set Location',
                           'Where does this partner operate? Add a physical address and/or service areas.')
        p(class: 'text-sm text-red-700 mb-4', data: { 'partner-wizard-target': 'locationHint' }) do
          plain t('admin.partners.validation.location_required')
        end
        div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
          FormCard(icon: :map, title: attr_label(:partner, :address)) do
            div(data: { 'partner-wizard-target': 'addressFields', action: 'input->partner-wizard#updateContinueButton' }) do
              AddressFields(form: form, partner: partner)
              div(class: 'alert alert-warning mt-4 hidden', data: { 'partner-wizard-target': 'addressIncompleteHint' }) do
                raw icon(:warning, size: '5', css_class: 'shrink-0')
                span { t('admin.partners.validation.address_incomplete') }
              end
            end
          end
          FormCard(
            icon: :car, title: t('admin.sections.service_areas'),
            description: "#{t('admin.partners.sections.service_areas_description')} #{t('admin.partners.sections.service_areas_hint')}",
            fit_height: true
          ) do
            div(data: { 'partner-wizard-target': 'serviceAreasContainer',
                        action: 'nested-form:added->partner-wizard#updateContinueButton nested-form:removed->partner-wizard#updateContinueButton change->partner-wizard#updateContinueButton' }) do
              nested_form_for(form, :service_areas,
                              add_text: t('admin.service_areas.add'),
                              add_class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange',
                              partial: 'service_area_fields') do
                raw form.simple_fields_for(:service_areas) { |nf| view_context.render('service_area_fields', f: nf) }
              end
            end
          end
        end
      end
    end
  end

  def render_step_tags(form)
    wizard_card(step: 3) do
      div(class: 'card-body') do
        render_step_header(:tag, 'Tags & Categories',
                           'Add partnerships and categories for this partner.')
        div(class: 'space-y-6') do
          raw view_context.render('partnership_fields', f: form)
          render_categories_field
          render_facilities_field
        end
      end
    end
  end

  def render_categories_field
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6',
             data: { controller: 'checkbox-limit', 'checkbox-limit-max-value': Partner::MAX_CATEGORIES.to_s }) do
      legend(class: 'fieldset-legend text-base font-semibold') { t('admin.partners.categories.title') }
      p(class: 'text-sm text-gray-600 mb-3') do
        plain t('admin.partners.categories.hint', max: Partner::MAX_CATEGORIES)
        whitespace
        span(class: 'badge badge-sm badge-ghost ml-2', 'data-counter': true) { "0 / #{Partner::MAX_CATEGORIES}" }
      end
      div(class: 'grid grid-cols-2 sm:grid-cols-3 gap-x-6 gap-y-2') do
        Category.all.each do |category|
          label(class: 'label cursor-pointer gap-2 justify-start py-1 transition-opacity') do
            raw check_box_tag('partner[category_ids][]', category.id,
                              partner.categories.include?(category),
                              class: 'checkbox checkbox-sm checkbox-warning', id: "category_#{category.id}")
            span(class: 'label-text text-sm') { category.name }
          end
        end
      end
      raw hidden_field_tag('partner[category_ids][]', '')
    end
  end

  def render_facilities_field
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6') do
      legend(class: 'fieldset-legend text-base font-semibold') { t('admin.partners.facilities.title') }
      p(class: 'text-sm text-gray-600 mb-3') { t('admin.partners.facilities.hint') }
      div(class: 'grid grid-cols-2 sm:grid-cols-3 gap-x-6 gap-y-2') do
        Facility.all.each do |facility|
          label(class: 'label cursor-pointer gap-2 justify-start py-1') do
            raw check_box_tag('partner[facility_ids][]', facility.id,
                              partner.facilities.include?(facility),
                              class: 'checkbox checkbox-sm checkbox-warning', id: "facility_#{facility.id}")
            span(class: 'label-text text-sm') { facility.name }
          end
        end
      end
      raw hidden_field_tag('partner[facility_ids][]', '')
    end
  end

  def render_step_contact(form)
    wizard_card(step: 4) do
      div(class: 'card-body') do
        render_step_header(:phone, 'Contact Information',
                           'How can people get in touch with this partner?')
        div(class: 'space-y-6') do
          render_online_presence(form)
          div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
            render_public_contact(form)
            render_partnership_contact(form)
          end
        end
      end
    end
  end

  def render_online_presence(form)
    FormCard(
      icon: :desktop, title: t('admin.sections.online_presence'),
      description: t('admin.partners.sections.online_presence_description')
    ) do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { attr_label(:partner, :website) }
        raw form.input_field(:url, class: 'input input-bordered w-full bg-base-100',
                                   placeholder: t('admin.partners.fields.website_placeholder'))
      end
      div(class: 'grid grid-cols-1 sm:grid-cols-3 gap-3') do
        render_social_field(form, :facebook_link, attr_label(:partner, :facebook), 'facebook.com/')
        render_social_field(form, :twitter_handle, attr_label(:partner, :twitter), '@')
        render_social_field(form, :instagram_handle, attr_label(:partner, :instagram), '@')
      end
    end
  end

  def render_social_field(form, field, label_text, prefix)
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { label_text }
      label(class: 'input input-bordered flex items-center gap-1 bg-base-100') do
        span(class: 'text-gray-600 text-sm shrink-0') { prefix }
        raw form.input_field(field, class: 'grow bg-transparent border-0 focus:outline-none min-w-0')
      end
    end
  end

  def render_public_contact(form)
    FormCard(
      icon: :website, title: t('admin.sections.public_contact'), description: t('admin.hints.shown_publicly')
    ) do
      render_contact_field(form, :public_name, attr_label(:partner, :name), 'partner-wizard-target': 'publicName')
      render_contact_field(form, :public_email, attr_label(:partner, :email), 'partner-wizard-target': 'publicEmail')
      render_contact_field(form, :public_phone, attr_label(:partner, :phone), 'partner-wizard-target': 'publicPhone')
    end
  end

  def render_partnership_contact(form)
    FormCard(
      icon: :partnership, title: t('admin.partners.sections.partnership_contact'),
      description: t('admin.partners.sections.partnership_contact_description')
    ) do
      render_contact_field(form, :partner_name, attr_label(:partner, :name))
      render_contact_field(form, :partner_email, attr_label(:partner, :email))
      render_contact_field(form, :partner_phone, attr_label(:partner, :phone))
    end
  end

  def render_contact_field(form, field, label_text, **data)
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { label_text }
      raw form.input_field(field, class: 'input input-bordered w-full bg-base-100', data: data)
    end
  end

  def render_step_invite(form)
    wizard_card(step: 5) do
      div(class: 'card-body') do
        render_step_header(:user_add, 'Invite a Partner Admin',
                           "Optionally invite someone to manage this partner. They'll receive an email invitation.")
        div(class: 'space-y-6') do
          div(class: 'flex items-center gap-3 p-4 bg-base-200/50 rounded-xl') do
            input(type: 'checkbox', class: 'checkbox checkbox-sm',
                  data: { 'partner-wizard-target': 'skipAdminCheckbox',
                          action: 'change->partner-wizard#toggleAdminFields' })
            label(class: 'text-sm') { "Skip this step - I'll add admins later" }
          end
          div(data: { 'partner-wizard-target': 'adminFields' }) do
            render_admin_details_card(form)
          end
        end
      end
    end
  end

  def render_admin_details_card(form)
    FormCard(
      icon: :user, title: 'Admin Details',
      description: 'Enter the details for the person who will manage this partner.'
    ) do
      div(class: 'grid grid-cols-1 md:grid-cols-2 gap-4') do
        fieldset(class: 'fieldset') do
          legend(class: 'fieldset-legend') { attr_label(:user, :first_name) }
          input(type: 'text', name: 'partner[invited_admin][first_name]',
                class: 'input input-bordered w-full bg-base-100',
                data: { 'partner-wizard-target': 'adminFirstName' })
        end
        fieldset(class: 'fieldset') do
          legend(class: 'fieldset-legend') { attr_label(:user, :last_name) }
          input(type: 'text', name: 'partner[invited_admin][last_name]',
                class: 'input input-bordered w-full bg-base-100',
                data: { 'partner-wizard-target': 'adminLastName' })
        end
      end
      render_admin_email_field(form)
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { attr_label(:user, :phone) }
        input(type: 'tel', name: 'partner[invited_admin][phone]',
              class: 'input input-bordered w-full bg-base-100',
              data: { 'partner-wizard-target': 'adminPhone' })
      end
      button(type: 'button', class: 'btn btn-sm btn-ghost gap-2 mt-2',
             data: { action: 'click->partner-wizard#copyFromContact' }) do
        raw icon(:clipboard, size: '4')
        plain 'Copy from partner contact info'
      end
    end
  end

  def render_admin_email_field(_form)
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') do
        plain attr_label(:user, :email)
        whitespace
        span(class: 'text-error') { t('admin.labels.required') }
      end
      input(type: 'email', name: 'partner[invited_admin][email]',
            class: 'input input-bordered w-full bg-base-100',
            data: { 'partner-wizard-target': 'adminEmail', action: 'input->partner-wizard#checkAdminEmail' })
      p(class: 'text-sm text-gray-600 mt-2') { 'An invitation email will be sent to this address.' }
      div(class: 'mt-3 hidden', data: { 'partner-wizard-target': 'adminEmailFeedback' }) do
        div(class: 'alert alert-success text-sm hidden', data: { 'partner-wizard-target': 'adminEmailAvailable' }) do
          raw icon(:check_circle, size: '5', css_class: 'shrink-0')
          span { 'This email address is available.' }
        end
        div(class: 'alert alert-warning text-sm hidden', data: { 'partner-wizard-target': 'adminEmailTaken' }) do
          raw icon(:warning, size: '5', css_class: 'shrink-0')
          div(class: 'flex-1') do
            p(class: 'font-semibold') { 'A user with this email already exists' }
            p(class: 'text-xs mt-1') { 'They will be added as an admin for this partner.' }
          end
        end
        div(class: 'alert alert-error text-sm hidden', data: { 'partner-wizard-target': 'adminEmailInvalid' }) do
          raw icon(:x_circle, size: '5', css_class: 'shrink-0')
          span { 'Please enter a valid email address.' }
        end
      end
    end
  end

  def render_step_confirm(_form)
    wizard_card(step: 6) do
      div(class: 'card-body') do
        render_step_header(:check_circle, 'Confirm & Create',
                           'Review what will be created, then click "Create Partner" below.',
                           icon_color: 'bg-emerald-100', icon_text_color: 'text-emerald-600')
        div(class: 'space-y-4') do
          div(class: 'alert bg-blue-50 border border-blue-200 text-blue-800') do
            raw icon(:partner, size: '5', css_class: 'shrink-0')
            div do
              p(class: 'font-semibold') { 'Partner will be created' }
              p(class: 'text-sm', data: { 'partner-wizard-target': 'confirmPartnerName' }) { '-' }
            end
          end
          div(class: 'alert bg-purple-50 border border-purple-200 text-purple-800 hidden',
              data: { 'partner-wizard-target': 'confirmAdminBox' }) do
            raw icon(:user_add, size: '5', css_class: 'shrink-0')
            div do
              p(class: 'font-semibold') { 'Admin will be invited' }
              p(class: 'text-sm', data: { 'partner-wizard-target': 'confirmAdminDetails' }) { '-' }
            end
          end
        end
        render_after_create_options
      end
    end
  end

  def render_after_create_options
    div(class: 'space-y-4 mt-6') do
      h3(class: 'font-semibold text-sm text-gray-600') { 'After creating, I want to:' }
      div(class: 'grid grid-cols-1 md:grid-cols-2 gap-4') do
        render_after_create_radio('edit', :partner, 'bg-blue-100', 'text-blue-600',
                                  'Edit Partner', 'Add more details, images, opening times', checked: true)
        render_after_create_radio('add_calendar', :calendar, 'bg-emerald-100', 'text-emerald-600',
                                  'Add Calendar', 'Import events from a calendar feed')
      end
    end
  end

  def render_after_create_radio(value, icon_name, bg_class, text_class, title, description, checked: false)
    label(class: 'cursor-pointer') do
      input(type: 'radio', name: 'after_create', value: value, class: 'peer sr-only', **(checked ? { checked: true } : {}))
      div(class: 'card bg-base-100 border-2 border-base-300 peer-checked:border-placecal-orange peer-checked:bg-placecal-orange/5 transition-colors') do
        div(class: 'card-body p-4') do
          div(class: 'flex items-center gap-3') do
            div(class: "w-10 h-10 rounded-lg #{bg_class} flex items-center justify-center") do
              raw icon(icon_name, size: '5', css_class: text_class)
            end
            div do
              p(class: 'font-semibold') { title }
              p(class: 'text-xs text-gray-600') { description }
            end
          end
        end
      end
    end
  end
end
