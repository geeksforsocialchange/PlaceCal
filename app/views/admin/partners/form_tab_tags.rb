# frozen_string_literal: true

class Views::Admin::Partners::FormTabTags < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    partner = form.object

    SectionHeader(
      title: t('admin.partners.sections.tags_associations'),
      description: t('admin.partners.sections.tags_description')
    )

    div(class: 'space-y-6 max-w-2xl') do
      render Views::Admin::Partners::PartnershipFields.new(form: form)
      render_facilities(partner)
      render_categories(partner)
    end
  end

  private

  def render_facilities(partner)
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { t('admin.partners.facilities.title') }
      p(class: 'fieldset-label mb-3') { t('admin.partners.facilities.hint') }
      div(class: 'grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-x-6 gap-y-2') do
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

  def render_categories(partner)
    fieldset(class: 'fieldset',
             data: { controller: 'checkbox-limit', 'checkbox-limit-max-value': Partner::MAX_CATEGORIES.to_s }) do
      legend(class: 'fieldset-legend') { t('admin.partners.categories.title') }
      p(class: 'fieldset-label mb-3') do
        plain t('admin.partners.categories.hint', max: Partner::MAX_CATEGORIES)
        whitespace
        span(class: 'badge badge-sm badge-ghost ml-2', 'data-counter': true) { "0 / #{Partner::MAX_CATEGORIES}" }
      end
      div(class: 'grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-x-6 gap-y-2') do
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
end
