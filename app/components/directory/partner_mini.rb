# frozen_string_literal: true

class Components::Directory::PartnerMini < Components::Directory::Base
  prop :partner, ::Partner
  prop :event_count, Integer, default: 0

  def view_template
    a(href: partner_path(@partner),
      class: 'group block py-2.5 pb-5 no-underline text-foreground hover:bg-home-background-3 transition-colors rounded-lg px-2 -mx-2') do
      div do
        div(class: 'flex items-start justify-between gap-2') do
          span(class: 'font-bold text-base leading-tight') { @partner.name }
          render_event_badge
        end
        div(class: 'border-b-[3px] border-rules group-hover:border-tertiary/20 pb-1 mb-1.5')
        div(class: 'text-sm text-tertiary font-bold mb-0.5') { area_text } if area_text.present?
        div(class: 'text-foreground text-sm leading-snug mt-1 line-clamp-2') { @partner.summary.truncate(120) } if @partner.summary.present?
        render_chips
      end
    end
  end

  private

  def render_event_badge
    return unless @event_count.positive?

    span(class: 'badge badge--tight bg-primary text-foreground whitespace-nowrap shrink-0') do
      plain "#{@event_count} #{'event'.pluralize(@event_count)}"
    end
  end

  def render_chips
    chips = @partner.categories.first(2).map(&:name)
    return if chips.empty?

    div(class: 'flex flex-wrap gap-1 mt-1.5') do
      chips.each do |label|
        span(class: 'badge badge--tight bg-home-background-3 text-tertiary') do
          plain label
        end
      end
    end
  end

  def area_text
    return @area_text if defined?(@area_text)

    hood = @partner.address&.neighbourhood
    hood ||= @partner.service_area_neighbourhoods.first if @partner.has_service_areas?
    @area_text = hood&.name
  end
end
