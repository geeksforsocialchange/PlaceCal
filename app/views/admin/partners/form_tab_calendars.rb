# frozen_string_literal: true

class Views::Admin::Partners::FormTabCalendars < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    partner = form.object

    h2(class: 'text-lg font-bold mb-1 flex items-center gap-2') do
      raw icon(:calendar, size: '5')
      plain Calendar.model_name.human(count: 2)
      whitespace
      span(class: 'badge badge-sm badge-ghost') { partner.calendars.count.to_s }
    end
    p(class: 'text-sm text-gray-600 mb-6') { t('admin.partners.sections.calendars_description') }

    render Components::Admin::RelatedItemsList.new(
      items: partner.calendars,
      title_attr: :name,
      subtitle_attr: :source,
      edit_path: ->(item) { helpers.edit_admin_calendar_path(item) },
      empty_message: t('admin.empty.none_connected', items: Calendar.model_name.human(count: 2).downcase)
    )

    div(class: 'mt-6') do
      link_to helpers.new_admin_calendar_path(partner_id: partner.id),
              class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange' do
        raw icon(:plus, size: '4')
        plain t('admin.actions.add_model', model: Calendar.model_name.human)
      end
    end
  end
end
