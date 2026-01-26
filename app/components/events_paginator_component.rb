# frozen_string_literal: true

# Date navigation paginator for events browser
# Displays navigation buttons for moving through dates
class EventsPaginatorComponent < ViewComponent::Base
  DEFAULT_STEPS = 7

  attr_reader :pointer, :period, :sort, :repeating, :step

  # rubocop:disable Metrics/ParameterLists
  def initialize(pointer:, period:, sort:, repeating:, step:, steps: DEFAULT_STEPS)
    # rubocop:enable Metrics/ParameterLists
    super()
    @pointer = pointer
    @period = period
    @sort = sort
    @repeating = repeating
    @step = step
    @steps = steps - 1
  end

  def pages
    items = []

    # Back arrow
    items << {
      text: back_arrow,
      url: url_for_date(pointer - step),
      css: 'paginator__arrow paginator__arrow--back',
      data: {}
    }

    # Date buttons
    (0..@steps).each do |i|
      day = pointer + (step * i)
      items << {
        text: format_date(day),
        url: url_for_date(day),
        css: active?(day) ? 'active' : '',
        data: { paginator_target: 'button' }
      }
    end

    # Forward arrow
    items << {
      text: forward_arrow,
      url: url_for_date(pointer + step),
      css: 'paginator__arrow paginator__arrow--forwards',
      data: { paginator_target: 'forward' }
    }

    items
  end

  def title
    if step <= 1.day
      pointer.strftime('%A %e %B, %Y')
    else
      start_date = pointer.strftime('%A %e %B')
      end_date = (pointer + step - 1.day).strftime('%A %e %B %Y')
      "#{start_date} - #{end_date}"
    end
  end

  private

  def url_for_date(date)
    params = { period: period, sort: sort, repeating: repeating }.to_query
    "/events/#{date.year}/#{date.month}/#{date.day}?#{params}#paginator"
  end

  def format_date(date)
    step <= 1.day ? todayify(date) : weekify(date)
  end

  def todayify(date)
    today = Time.zone.today
    return 'Today' if date == today
    return 'Tomorrow' if date == today + 1.day

    date.strftime('%a %e %b')
  end

  def weekify(date)
    today = Time.zone.today
    return 'This week' if date == today.beginning_of_week

    end_date = date + step - 1.day
    if date.month == end_date.month
      "#{date.strftime('%e')} - #{end_date.strftime('%e %b')}"
    else
      "#{date.strftime('%e %b')} - #{end_date.strftime('%e %b')}"
    end
  end

  def active?(day)
    pointer == day
  end

  def back_arrow
    '<span class="icon icon--arrow-left-grey">&larr;</span>'.html_safe
  end

  def forward_arrow
    '<span class="icon icon--arrow-right-grey">&rarr;</span>'.html_safe
  end
end
