# frozen_string_literal: true

class Components::Directory::PartnerCard < Components::Directory::Base
  prop :partner, ::Partner
  prop :site, ::Site

  def view_template
    a(href: partner_path(@partner),
      class: [
        'grid grid-cols-[52px_1fr] gap-3 items-start',
        'py-3 px-4 rounded-card border-2 border-transparent',
        'no-underline text-foreground hover:border-rules transition-colors'
      ].join(' '),
      id: "partner-#{@partner.id}") do
      render_avatar
      render_info
    end
  end

  private

  def render_avatar
    if @partner.image?
      img(
        src: @partner.image.standard.url,
        alt: @partner.name,
        class: 'w-[52px] h-[52px] rounded-full object-cover'
      )
    else
      div(class: 'w-[52px] h-[52px] rounded-full bg-home-background-3 flex items-center justify-center font-serif text-xl text-tertiary') do
        plain initials
      end
    end
  end

  def render_info
    div do
      div(class: 'font-extra-bold text-detail leading-tight mb-0.5') { @partner.name }
      div(class: 'text-xs text-tertiary leading-snug mb-1.5') { area_text } if area_text.present?
      render_chips
    end
  end

  def render_chips
    chips = @partner.categories.first(2).map(&:name)
    return if chips.empty?

    div(class: 'flex flex-wrap gap-1') do
      chips.each do |label|
        span(class: 'inline-flex items-center bg-home-background-3 text-tertiary text-2xs font-bold rounded-full px-2 py-0.5') do
          plain label
        end
      end
    end
  end

  def initials
    @partner.name.split.first(2).map { |w| w[0] }.join.upcase
  end

  def area_text
    @partner.location_name
  end
end
