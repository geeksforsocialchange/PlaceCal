# frozen_string_literal: true

class Views::Admin::Calendars::Sources < Views::Admin::Base
  prop :parsers, Array, reader: :private

  def view_template
    content_for(:title) { t('admin.calendars.sources.title') }

    div(class: 'bg-white shadow-sm rounded-xl overflow-hidden border border-gray-200') do
      div(class: 'px-6 py-5 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-white') do
        h1(class: 'text-xl font-semibold text-gray-900') { t('admin.calendars.sources.title') }
        p(class: 'mt-1 text-sm text-gray-600') { t('admin.calendars.sources.intro') }
      end
      div(class: 'overflow-x-auto') do
        table(class: 'table table-sm') do
          thead do
            tr do
              th(scope: 'col') { t('admin.calendars.sources.source') }
              th(scope: 'col') { t('admin.calendars.sources.tier') }
              fields.each { |field| th(scope: 'col') { t("admin.calendars.sources.fields.#{field}") } }
            end
          end
          tbody { parsers.each { |parser| render_row(parser) } }
        end
      end
      render_tiers
    end
  end

  private

  def render_tiers
    dl(class: 'px-6 py-5 border-t border-gray-200 text-sm text-gray-600 space-y-1') do
      CalendarImporter::Parsers::Base::TIERS.each do |tier|
        div do
          dt(class: 'inline font-medium text-gray-900') { t("admin.calendars.sources.tiers.#{tier}.label") }
          whitespace
          dd(class: 'inline') { t("admin.calendars.sources.tiers.#{tier}.description") }
        end
      end
    end
  end

  def fields = CalendarImporter::Events::Base::FIELDS.keys

  def render_row(parser)
    field_map = parser.event_class.field_map
    tr(class: 'align-top') do
      th(scope: 'row', class: 'font-medium text-gray-900') do
        div do
          if parser.handbook_url
            link_to parser::NAME, parser.handbook_url, class: 'link link-hover text-placecal-orange-dark'
          else
            plain parser::NAME
          end
        end
        div(class: 'text-xs font-normal text-gray-600') { parser::DOMAINS.presence&.join(', ') || t('admin.calendars.sources.any_website') }
      end
      td(class: 'whitespace-nowrap') { t("admin.calendars.sources.tiers.#{parser::TIER}.label") }
      fields.each { |field| td { render_cell(field_map[field]) } }
    end
  end

  def render_cell(source_fields)
    if source_fields.blank?
      span(class: 'text-xs italic text-gray-600') { t('admin.calendars.sources.not_imported') }
    else
      ul(class: 'space-y-0.5') { Array(source_fields).each { |name| li { code(class: 'text-xs') { name } } } }
    end
  end
end
