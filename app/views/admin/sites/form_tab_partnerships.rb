# frozen_string_literal: true

class Views::Admin::Sites::FormTabPartnerships < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    site = form.object

    SectionHeader(
      title: Partnership.model_name.human(count: 2),
      description: t('admin.sites.sections.partnerships_description')
    )

    div(class: 'max-w-xl') do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { t('admin.sites.fields.partnership_tags') }
        p(id: 'site_tag_ids-hint', class: 'fieldset-label mb-3') { t('admin.sites.fields.partnership_tags_hint') }
        div(class: 'site_tags') do
          if policy(site).permitted_attributes.include?(:tags)
            raw form.input_field(:tag_ids,
                                 as: :select,
                                 collection: options_for_tags,
                                 multiple: true,
                                 class: 'select select-bordered w-full',
                                 aria: { label: t('admin.sites.fields.partnership_tags'), describedby: 'site_tag_ids-hint' },
                                 data: { controller: 'tom-select' })
          else
            raw form.input_field(:tag_ids,
                                 as: :select,
                                 collection: options_for_tags,
                                 multiple: true,
                                 class: 'select select-bordered w-full bg-base-200',
                                 disabled: true,
                                 aria: { label: t('admin.sites.fields.partnership_tags'), describedby: 'site_tag_ids-hint' },
                                 data: { controller: 'tom-select' })
          end
        end
      end
    end
  end
end
