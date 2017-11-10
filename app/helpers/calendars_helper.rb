module CalendarsHelper
  def summarize_dates(dates)
    if dates.length > 3
      sorted = dates.sort
      "#{dates.count} dates between #{sorted.first.strftime("%a, %b %e, %Y")} and #{sorted.last.strftime("%a, %b %e, %Y")}"
    else
      dates.map { |date| date.strftime("%b %e %Y (%a)") }.join(", ")
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
