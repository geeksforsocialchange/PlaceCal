# app/components/paginator/paginator_component.rb
class PaginatorComponent < MountainView::Presenter
  properties :current_day, :period, :steps, :path

  DEFAULT_STEPS = 7

  # Reference start date
  def pointer
    properties[:current_day]
  end

  # How far each step takes us
  def period
    properties[:period] == 'week' ? 1.week : 1.day
  end

  # Create URLs
  def create_event_url(dt)
    "/#{path}/#{dt.year}/#{dt.month}/#{dt.day}#{url_suffix}"
  end

  # Back link
  def backwards
    create_event_url(pointer - (period * steps))
  end

  # Forwards link
  def forwards
    create_event_url(pointer + (period * steps))
  end

  # Number of options in paginator
  def steps
    # Current day is 0, prevents off-by-one error
    (properties[:steps] || DEFAULT_STEPS) - 1
  end

  # Format date
  def d_short(date)
    # Fri 15th Sep
    date.strftime('%a %e %b')
  end

  private

  # Base URL
  def path
    properties[:path] || 'events'
  end

  # URL params to add back in
  def url_suffix
    properties[:period] == 'week' ? '?period=week' : ''
  end
end
