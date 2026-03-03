# frozen_string_literal: true

class Views::Admin::Partners::PartnershipFields < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    partner = form.object
    current_user = helpers.current_user

    return unless current_user.partnership_admin? || current_user.root?

    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { Partnership.model_name.human(count: 2) }
      p(class: 'fieldset-label mb-3') { t('admin.partners.sections.tags_description') }

      render Components::Admin::StackedListSelector.new(
        field_name: 'partner[partnership_ids][]',
        items: partner.partnerships,
        options: options_for_partner_partnerships,
        permitted_ids: current_user.root? ? nil : permitted_options_for_partner_tags,
        icon_name: :partnership,
        icon_color: 'bg-placecal-orange/10 text-placecal-orange',
        empty_text: t('admin.empty.none_assigned', items: Partnership.model_name.human(count: 2).downcase),
        add_placeholder: t('admin.placeholders.add_model', model: Partnership.model_name.human.downcase)
      )
    end
  end
end
