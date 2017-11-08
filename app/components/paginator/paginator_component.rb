# app/components/paginator/paginator_component.rb
class PaginatorComponent < MountainView::Presenter
  properties :pointer, :period, :steps, :path, :sort, :repeating
  # FIXME: find a more elegant way of handling this
  property :show_breadcrumb, default: true

  DEFAULT_STEPS = 7

  # Link array
  def paginator # rubocop:disable Metrics/AbcSize
    pages = []
    # Create backward arrow link
    pages << { text: back_arrow, link: create_event_url(pointer - period), css: 'js-back' }
    # Create in-between links according to steps requested
    (0..steps).each do |i|
      day = pointer + period * i
      css = active?(day) ? 'active js-button' : 'js-button'
      pages << { text: format_date(day),
                 link: create_event_url(day),
                 css: css }
    end
    # Create forwards arrow link
    pages << { text: forward_arrow, link: create_event_url(pointer + period), css: 'js-forwards' }
  end

  # Paginator title
  def title
    if period <= 1.day
      # Thursday 14 September, 2017
      pointer.strftime('%A %e %B, %Y')
    else
      # Thursday 14 September - 21 September 2017
      t = pointer.strftime('%A %e %B')
      t += ' - '
      # FIXME: 1.day needs sorting when we add in month views
      t + (pointer + period - 1.day).strftime('%A %e %B %Y')
    end
  end

  # What field are we using to sort?
  def sort
    properties[:sort] || 'time'
  end

  # How far does each step take us?
  def period
    properties[:period] == 'week' ? 1.week : 1.day
  end

  # Base URL
  def path
    properties[:path] || 'events'
  end

  # Number of steps for the paginator to have
  def steps
    (properties[:steps] || DEFAULT_STEPS) - 1
  end

  private

  # Which day are we doing our calculations based on?
  def pointer
    if period == 1.week
      # This should be set by the model, but just to be sure
      properties[:pointer].beginning_of_week
    else
      properties[:pointer]
    end
  end

  # Format date according to context
  def format_date(date)
    if period <= 1.day
      todayify(date)
    else
      weekify(date)
    end
  end

  # Format the button for a day or less of events
  def todayify(date)
    today = Date.today
    date_fmt = date.strftime('%a %e %b')
    # Show day name e.g. "Fri 15th Sep"
    if date == today
      'Today'
    elsif date == today + 1.day
      'Tomorrow'
    else
      date_fmt
    end
  end

  # Format the button for a week of events
  def weekify(date) # rubocop:disable Metrics/MethodLength
    today = Date.today
    end_date = date + period - 1.day
    date_fmt = if date.month == end_date.month
                 "#{date.strftime('%e')} - #{end_date.strftime('%e %b')}"
               else
                 # Show date range e.g. "15 Sep - 22 Sep"
                 "#{date.strftime('%e %b')} – #{end_date.strftime('%e %b')}"
               end
    # Add in note if it's the current week
    if date == today.beginning_of_week
      'This week'
    else
      date_fmt
    end
  end

  # Create URLs
  def create_event_url(dt)
    "/#{path}/#{dt.year}/#{dt.month}/#{dt.day}#{url_suffix}"
  end

  # URL params to add back in
  def url_suffix
    str = []
    str << 'period=week' if period == 1.week
    str << "sort=#{sort}" if sort
    '?' + str.join('&') if str.any?
  end

  # Icon for back arrow
  def back_arrow
    '<span class="icon icon--arrow-left-grey">←</span>'.html_safe
  end

  # Icon for forward arrow
  def forward_arrow
    '<span class="icon icon--arrow-right-grey">→</span>'.html_safe
  end

  # Is this the current active day?
  def active?(day)
    pointer == day
  end
end
