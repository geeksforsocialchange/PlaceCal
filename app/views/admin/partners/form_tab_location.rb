# frozen_string_literal: true

class Views::Admin::Partners::FormTabLocation < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    partner = form.object

    SectionHeader(
      title: t('admin.tabs.location'),
      description: t('admin.partners.sections.location_description')
    )

    div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
      div(class: 'space-y-6') do
        FormCard(icon: :map, title: attr_label(:partner, :address)) do
          AddressFields(form: form, partner: partner, current_user: helpers.current_user)
          render_outdated_neighbourhood_warning(partner)
          render_unmappable_postcode_warning(partner)
          render_neighbourhood_display(partner)
        end
      end

      render_service_areas
    end

    div(class: 'mt-6') do
      FormCard(icon: :clock, title: t('admin.sections.opening_times')) do
        OpeningTimes(form: form, partner: partner)
      end
    end
  end

  private

  def render_outdated_neighbourhood_warning(partner)
    return unless partner&.address&.neighbourhood&.legacy_neighbourhood? # rubocop:disable Style/SafeNavigationChainLength

    div(role: 'alert', class: 'alert alert-warning text-sm') do
      raw icon(:warning, size: '5', css_class: 'shrink-0')
      span { raw safe(t('admin.partners.warnings.outdated_neighbourhood', email: 'support@placecal.org')) }
    end
  end

  def render_unmappable_postcode_warning(partner)
    return unless partner_has_unmappable_postcode?(partner)

    div(role: 'alert', class: 'alert alert-warning text-sm') do
      raw icon(:warning, size: '5', css_class: 'shrink-0')
      span { t('admin.partners.warnings.unmappable_postcode') }
    end
  end

  def render_neighbourhood_display(partner)
    return if partner.address&.neighbourhood.blank?

    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend flex items-center gap-1') do
        raw icon(:neighbourhood, size: '4')
        plain t('admin.address.neighbourhood_label')
      end
      NeighbourhoodCard(
        neighbourhood: partner.address.neighbourhood,
        show_header: false
      )
    end
  end

  def render_service_areas
    FormCard(
      icon: :car,
      title: t('admin.sections.service_areas'),
      description: "#{t('admin.partners.sections.service_areas_description')} #{t('admin.partners.sections.service_areas_hint')}",
      fit_height: true
    ) do
      nested_form_for(form, :service_areas,
                      add_text: t('admin.service_areas.add'),
                      add_class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange',
                      partial: 'service_area_fields') do
        raw form.simple_fields_for(:service_areas) { |neighbourhood|
          view_context.render('service_area_fields', f: neighbourhood)
        }
      end
    end
  end
end
