# frozen_string_literal: true

class Components::Directory::PartnerCard < Components::Directory::Base
  prop :partner, ::Partner
  prop :site, ::Site

  def view_template
    a(href: partner_path(@partner),
      class: 'group block py-3 pb-7 no-underline text-foreground hover:bg-home-background-3 transition-colors rounded-lg px-2 -mx-2 break-inside-avoid',
      id: "partner-#{@partner.id}") do
      render_info
    end
  end

  private

  def render_info
    div do
      div(class: 'font-bold text-xl leading-tight border-b-[3px] border-rules group-hover:border-tertiary/20 pb-1.5 mb-1.5') { @partner.name }
      div(class: 'text-sm text-tertiary font-bold mb-0.5') { area_text } if area_text.present?
      div(class: 'text-foreground leading-snug mt-1 line-clamp-2') { @partner.summary.truncate(120) } if @partner.summary.present?
      render_chips
    end
  end

  def render_chips
    chips = @partner.categories.first(2).map(&:name)
    return if chips.empty?

    div(class: 'flex flex-wrap gap-1 mt-2.5') do
      chips.each do |label|
        span(class: 'inline-flex items-center bg-home-background-3 text-tertiary text-2xs font-bold rounded-full px-2 py-0.5') do
          plain label
        end
      end
    end
  end

  def area_text
    hood = @partner.address&.neighbourhood
    hood ||= @partner.service_area_neighbourhoods.first if @partner.has_service_areas?
    return unless hood

    hood.hierarchy_path.last(3).map(&:shortname).join(' › ')
  end
end
