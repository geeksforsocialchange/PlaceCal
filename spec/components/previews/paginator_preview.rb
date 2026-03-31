# frozen_string_literal: true

class PaginatorPreview < Lookbook::Preview
  # @label Day view
  def day_view
    render Components::Paginator.new(
      pointer: Time.zone.today,
      period: "day",
      sort: "time",
      site_name: "The Community Calendar"
    )
  end

  # @label Week view
  def week_view
    render Components::Paginator.new(
      pointer: Time.zone.today,
      period: "week",
      sort: "time",
      site_name: "The Community Calendar"
    )
  end

  # @label Without breadcrumb
  def without_breadcrumb
    render Components::Paginator.new(
      pointer: Time.zone.today,
      period: "day",
      sort: "time",
      show_breadcrumb: false
    )
  end
end
