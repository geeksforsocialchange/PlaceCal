# frozen_string_literal: true

class Datatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegator :@view, :link_to
  def_delegator :@view, :edit_admin_article_path
  def_delegator :@view, :edit_admin_neighbourhood_path
  def_delegator :@view, :admin_neighbourhood_path
  def_delegator :@view, :edit_admin_user_path
  def_delegator :@view, :edit_admin_partner_path
  def_delegator :@view, :edit_admin_site_path
  def_delegator :@view, :edit_admin_tag_path
  def_delegator :@view, :edit_admin_calendar_path
  def_delegator :@view, :edit_admin_partnership_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  # Override to ensure draw is included - parent class has issue with draw_id
  def as_json(*)
    result = super
    result[:draw] = params[:draw].to_i if params[:draw].present?
    result
  end

  # Default implementation - subclasses define records_key
  def records_total_count
    options[records_key].count
  end

  # Default implementation - Partner overrides for GROUP BY handling
  def records_filtered_count
    filter_records(get_raw_records).except(:limit, :offset, :order).count
  end

  protected

  # Override in subclass to specify the options key (e.g., :calendars, :partners)
  def records_key
    raise NotImplementedError, 'Subclass must define records_key (e.g., :calendars)'
  end

  # Override in subclass to specify the edit path helper
  def edit_path_for(record)
    raise NotImplementedError, 'Subclass must define edit_path_for'
  end

  # Shared actions cell - override for custom behavior
  def render_actions(record)
    <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
      <div class="flex items-center gap-2">
        <a href="#{edit_path_for(record)}"
           class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500">
          Edit
        </a>
      </div>
    HTML
  end

  # Delegate to SvgIconsHelper via view context
  def icon(name, size: '4', css_class: '')
    @view.icon(name, size:, css_class:).to_s
  end

  # Shared relative time formatting for datatable cells
  def render_relative_time(datetime)
    return '<span class="text-gray-500">—</span>'.html_safe unless datetime

    days_ago = (Time.current - datetime).to_i / 1.day

    relative = if days_ago.zero?
                 'Today'
               elsif days_ago == 1
                 'Yesterday'
               elsif days_ago < 7
                 "#{days_ago} days ago"
               elsif days_ago < 30
                 weeks = days_ago / 7
                 "#{weeks} week#{'s' if weeks != 1} ago"
               else
                 datetime.strftime('%-d %b %Y')
               end

    <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
      <span class="text-gray-500 text-sm whitespace-nowrap" title="#{datetime.strftime('%d %b %Y at %H:%M')}">#{relative}</span>
    HTML
  end

  INDICATOR_COLOURS = {
    ok: 'text-emerald-700',
    none: 'text-gray-500',
    warning: 'text-amber-700',
    error: 'text-red-600',
    queued: 'text-orange-700',
    working: 'text-orange-700',
    system: 'text-amber-700',
    custom: 'text-gray-500'
  }.freeze

  # An icon-only status: data-status is the hook for specs, the label is what screen readers hear.
  def render_indicator(status, label, icon_html, count: nil)
    label = ERB::Util.html_escape(label)
    count_html = count ? %(<span class="ml-1 text-xs">#{count}</span>) : ''

    <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
      <span class="inline-flex items-center #{INDICATOR_COLOURS.fetch(status)}" role="img" aria-label="#{label}" title="#{label}" data-status="#{status}">
        #{icon_html}#{count_html}
      </span>
    HTML
  end

  def render_count_cell(count, label)
    if count.positive?
      render_indicator(:ok, "#{count} #{label}#{'s' if count != 1}", icon(:check), count:)
    else
      render_indicator(:none, "No #{label}s", icon(:x))
    end
  end

  # Empty cell placeholder
  def empty_cell
    '<span class="text-gray-500">—</span>'.html_safe
  end
end
