# frozen_string_literal: true

module CalendarsHelper
  def options_for_organiser
    org_opts = policy_scope(Partner).order(:name).collect { |opt| [ opt.name, opt.id ] }

    #[{ name: '', id: ''}] + org_opts
    [[ '(No Partner)', '', { disabled: true }]] + org_opts
  end

  def options_for_location
    policy_scope(Partner).order(:name)
  end

  def summarize_dates(dates)
    if dates.length > 3
      sorted = dates.sort
      "#{dates.count} dates between #{sorted.first.strftime('%a, %b %e, %Y')} and #{sorted.last.strftime('%a, %b %e, %Y')}"
    else
      dates.map { |date| date.strftime('%b %e %Y (%a)') }.join(', ')
    end
  end

  def display_time_since(date)
    if DateTime.current.to_date == date.to_date
      'Today'
    else
      "#{(Date.current - date).to_i} Days Ago"
    end
  end
end
