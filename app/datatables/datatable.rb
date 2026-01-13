# frozen_string_literal: true

# rubocop:disable Rails/OutputSafety
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

  protected

  # Delegate to SvgIconsHelper via view context
  def icon(name, size: '4', css_class: '')
    @view.icon(name, size: size, css_class: css_class).to_s
  end

  # Shared relative time formatting for datatable cells
  def render_relative_time(datetime)
    return '<span class="text-gray-400">—</span>'.html_safe unless datetime

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

    <<~HTML.html_safe
      <span class="text-gray-500 text-sm whitespace-nowrap" title="#{datetime.strftime('%d %b %Y at %H:%M')}">#{relative}</span>
    HTML
  end

  # Shared status icon rendering
  def render_status_icon(status, tooltip: nil)
    config = status_icon_config(status)
    title = tooltip || config[:tooltip]

    <<~HTML.html_safe
      <span class="inline-flex items-center #{config[:color]}" title="#{title}">
        #{icon(config[:icon])}
      </span>
    HTML
  end

  # Shared count cell with checkmark or dash
  def render_count_cell(count, label)
    if count.positive?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-emerald-600" title="#{count} #{label}#{'s' if count != 1}">
          #{icon(:check)}
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="No #{label}s">
          #{icon(:x)}
        </span>
      HTML
    end
  end

  # Empty cell placeholder
  def empty_cell
    '<span class="text-gray-400">—</span>'.html_safe
  end

  private

  def status_icon_config(status)
    {
      success: { icon: :check, color: 'text-emerald-600', tooltip: 'Success' },
      warning: { icon: :warning, color: 'text-amber-600', tooltip: 'Warning' },
      error: { icon: :warning, color: 'text-red-600', tooltip: 'Error' },
      pending: { icon: :x, color: 'text-gray-400', tooltip: 'Pending' },
      loading: { icon: :swap, color: 'text-orange-500', tooltip: 'Loading' }
    }.fetch(status.to_sym, { icon: :x, color: 'text-gray-400', tooltip: 'Unknown' })
  end
end
# rubocop:enable Rails/OutputSafety
