module CalendarsHelper
  def summarize_dates(dates)
    if dates.length > 3
      sorted = dates.sort
      "#{dates.count} dates between #{sorted.first.strftime("%a, %b %e, %Y")} and #{sorted.last.strftime("%a, %b %e, %Y")}"
    else
      dates.map { |date| date.strftime("%a, %b %e, %Y") }.join(", ")
    end
  end
end
