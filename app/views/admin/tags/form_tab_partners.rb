# frozen_string_literal: true

class Views::Admin::Tags::FormTabPartners < Views::Admin::Base
  include Phlex::Rails::Helpers::Truncate

  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    tag_record = form.object
    tag_partners = tag_record.partners.order(:name)

    div(class: 'max-w-4xl') do
      h3(class: 'text-lg font-bold mb-1 flex items-center gap-2') do
        raw icon(:partner, size: '5')
        plain t('admin.tags.sections.tagged_partners')
        span(class: 'inline-flex items-center justify-center h-6 px-2 text-xs rounded-full font-bold bg-emerald-100 text-emerald-700') do
          plain tag_partners.count.to_s
        end
      end
      p(class: 'text-sm text-gray-600 mb-4') { t('admin.tags.sections.tagged_partners_description') }

      if tag_partners.any?
        render_partners_table(tag_partners)
        if tag_partners.count > 50
          p(class: 'text-sm text-gray-600 mt-2') do
            plain t('admin.sites.preview.showing_first', limit: 50, total: tag_partners.count, items: Partner.model_name.human(count: 2).downcase)
          end
        end
      else
        render Components::Admin::EmptyState.new(
          icon: :partner,
          message: t('admin.empty.no_items', items: Partner.model_name.human(count: 2).downcase)
        )
      end
    end
  end

  private

  def render_partners_table(tag_partners) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'overflow-x-auto') do
      table(class: 'table table-sm table-zebra') do
        thead do
          tr do
            th { Partner.model_name.human }
            th { Calendar.model_name.human(count: 2) }
            th { ::Event.model_name.human(count: 2) }
          end
        end
        tbody do
          tag_partners.limit(50).each do |partner|
            render_partner_row(partner)
          end
        end
      end
    end
  end

  def render_partner_row(partner) # rubocop:disable Metrics/AbcSize
    tr do
      td do
        link_to(helpers.edit_admin_partner_path(partner), class: 'link link-hover text-placecal-orange font-medium') do
          plain partner.name
        end
        span(class: 'badge badge-error badge-xs ml-1') { t('admin.labels.hidden') } if partner.hidden
      end
      td { partner.calendars.count.to_s }
      td { partner.events.upcoming.count.to_s }
    end
  end
end
