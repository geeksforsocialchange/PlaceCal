# app/components/paginator/paginator_component.rb
class PaginatorComponent < MountainView::Presenter
  properties :pointer, :period, :steps, :path

  DEFAULT_STEPS = 7
  TODAY = Date.today

  # Which day are we doing our calculations based on?
  def pointer
    if period == 1.week
      properties[:pointer].beginning_of_week
    else
      properties[:pointer]
    end
  end

  # How far each step takes us
  def period
    properties[:period] == 'week' ? 1.week : 1.day
  end

  # Create URLs
  def create_event_url(dt)
    "/#{path}/#{dt.year}/#{dt.month}/#{dt.day}#{url_suffix}"
  end

  # Link array
  def paginator # rubocop:disable Metrics/AbcSize
    pages = []
    # Create backward arrow link
    pages << ['←', create_event_url(pointer - period)]
    # Create in-between links according to steps requested
    (0..steps).each do |i|
      day = pointer + period * i
      pages << [format_date(day), create_event_url(day)]
    end
    # Create forwards arrow link
    pages << ['→', create_event_url(pointer + period)]
  end

  def title
    if period <= 1.day
      # Thursday 14 September, 2017
      pointer.strftime('%A %e %B, %Y')
    else
      # Thursday 14 September - 21 September 2017
      pointer.strftime('%A %e %B') + ' - ' + (pointer + period).strftime('%e %B %Y')
    end
  end

  # Number of steps for the paginator to have
  def steps
    (properties[:steps] || DEFAULT_STEPS) - 1
  end

  # Format date according to context
  def format_date(date)
    if period <= 1.day
      # Show day name e.g. "Fri 15th Sep"
      if date == TODAY
        "Today (#{date.strftime('%a %e %b')})"
      elsif date == TODAY + 1.day
        "Tomorrow (#{date.strftime('%a %e %b')})"
      else
        date.strftime('%a %e %b')
      end
    else
      # Show date range e.g. "15 Sep - 22 Sep"
      date.strftime('%e %b') + ' - ' + (date + period).strftime('%e %b')
    end
  end

  private

  # Base URL
  def path
    properties[:path] || 'events'
  end

  # URL params to add back in
  def url_suffix
    period == 1.week ? '?period=week' : ''
  end
end
