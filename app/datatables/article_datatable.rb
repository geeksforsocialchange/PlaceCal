# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class ArticleDatatable < Datatable
  def view_columns
    @view_columns ||= {
      title: { source: 'Article.title', cond: :like, searchable: true },
      author: { source: 'users.first_name', searchable: false, orderable: true },
      partners: { source: 'Article.id', orderable: false, searchable: false },
      published_at: { source: 'Article.published_at', searchable: false, orderable: true },
      is_draft: { source: 'Article.is_draft', searchable: false, orderable: true },
      updated_at: { source: 'Article.updated_at', searchable: false, orderable: true },
      actions: { source: 'Article.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      {
        title: render_title_cell(record),
        author: render_author_cell(record),
        partners: render_partners_cell(record),
        published_at: render_published_at_cell(record),
        is_draft: render_draft_status_cell(record),
        updated_at: render_relative_time(record.updated_at),
        actions: render_actions(record)
      }
    end
  end

  def get_raw_records
    records = options[:articles]
              .includes(:author, :partners)
              .left_joins(:author, :partners)
              .references(:author, :partners)

    # Apply filters from request params
    if params[:filter].present?
      # Draft status filter
      if params[:filter][:is_draft].present?
        if params[:filter][:is_draft] == 'yes'
          records = records.where(is_draft: true)
        elsif params[:filter][:is_draft] == 'no'
          records = records.where(is_draft: false)
        end
      end

      # Has partners filter
      if params[:filter][:has_partners].present?
        if params[:filter][:has_partners] == 'yes'
          records = records.joins(:partners).distinct
        elsif params[:filter][:has_partners] == 'no'
          records = records.where.missing(:partners).distinct
        end
      end

      # Specific partner filter
      records = records.joins(:partners).where(partners: { id: params[:filter][:partner_id] }) if params[:filter][:partner_id].present?
    end

    records
  end

  def records_total_count
    options[:articles].count
  end

  def records_filtered_count
    filter_records(get_raw_records).except(:limit, :offset, :order).count
  end

  private

  def render_title_cell(record)
    <<~HTML.html_safe
      <div class="flex flex-col">
        <a href="#{edit_admin_article_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.title)}
        </a>
        <span class="text-xs text-gray-400 font-mono">##{record.id} · /#{ERB::Util.html_escape(record.slug)}</span>
      </div>
    HTML
  end

  def render_author_cell(record)
    return '<span class="text-gray-400">—</span>'.html_safe unless record.author

    author = record.author
    display_name = author.full_name.presence || author.email

    <<~HTML.html_safe
      <a href="#{edit_admin_user_path(author)}" class="link link-hover text-placecal-orange">
        #{ERB::Util.html_escape(display_name)}
      </a>
    HTML
  end

  def render_partners_cell(record)
    partners = record.partners
    return '<span class="text-gray-400">—</span>'.html_safe if partners.empty?

    if partners.size == 1
      partner = partners.first
      <<~HTML.html_safe
        <a href="#{edit_admin_partner_path(partner)}" class="text-gray-600 hover:text-orange-600">
          #{ERB::Util.html_escape(partner.name)}
        </a>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-600" title="#{ERB::Util.html_escape(partners.map(&:name).join(', '))}">
          #{partners.size} partners
        </span>
      HTML
    end
  end

  def render_published_at_cell(record)
    return '<span class="text-gray-400">—</span>'.html_safe unless record.published_at

    <<~HTML.html_safe
      <span class="text-gray-600 text-sm whitespace-nowrap">
        #{record.published_at.strftime('%-d %b %Y')}
      </span>
    HTML
  end

  def render_draft_status_cell(record)
    if record.is_draft?
      <<~HTML.html_safe
        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-amber-100 text-amber-800">
          Draft
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-emerald-100 text-emerald-800">
          Published
        </span>
      HTML
    end
  end

  def render_relative_time(datetime)
    return '<span class="text-gray-400">—</span>'.html_safe unless datetime

    days_ago = (Time.current - datetime).to_i / 1.day

    if days_ago.zero?
      relative = 'Today'
    elsif days_ago == 1
      relative = 'Yesterday'
    elsif days_ago < 7
      relative = "#{days_ago} days ago"
    elsif days_ago < 30
      weeks = days_ago / 7
      relative = "#{weeks} week#{'s' if weeks != 1} ago"
    else
      relative = datetime.strftime('%-d %b %Y')
    end

    <<~HTML.html_safe
      <span class="text-gray-500 text-sm whitespace-nowrap" title="#{datetime.strftime('%d %b %Y at %H:%M')}">#{relative}</span>
    HTML
  end

  def render_actions(record)
    <<~HTML.html_safe
      <div class="flex items-center gap-2">
        <a href="#{edit_admin_article_path(record)}"
           class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500">
          Edit
        </a>
      </div>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
