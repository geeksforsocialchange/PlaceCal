# frozen_string_literal: true

class PaginatorComponentPreview < ViewComponent::Preview
  # @label Day View
  def day_view
    render(PaginatorComponent.new(
             pointer: Time.zone.today,
             period: 'day'
           ))
  end

  # @label Week View
  def week_view
    render(PaginatorComponent.new(
             pointer: Time.zone.today.beginning_of_week,
             period: 'week'
           ))
  end

  # @label With Site Name
  def with_site_name
    render(PaginatorComponent.new(
             pointer: Time.zone.today,
             period: 'day',
             site_name: 'Hulme Events'
           ))
  end

  # @label Without Breadcrumb
  def without_breadcrumb
    render(PaginatorComponent.new(
             pointer: Time.zone.today,
             period: 'day',
             show_breadcrumb: false
           ))
  end

  # @label Custom Path
  def custom_path
    render(PaginatorComponent.new(
             pointer: Time.zone.today,
             period: 'day',
             path: 'partner/community-centre/events'
           ))
  end
end
