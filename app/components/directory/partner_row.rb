# frozen_string_literal: true

class Components::Directory::PartnerRow < Components::Directory::Base
  prop :partner, ::Partner
  prop :event_count, Integer, default: 0

  def view_template
    a(href: partner_path(@partner),
      class: [
        'grid grid-cols-[44px_1fr_auto] gap-3 items-center',
        'py-2.5 px-3 rounded-card border-2 border-transparent',
        'no-underline text-foreground hover:border-foreground transition-colors'
      ].join(' ')) do
      render_avatar
      render_info
      render_events_badge
    end
  end

  private

  def render_avatar
    div(class: 'w-11 h-11 rounded-full bg-home-background-3 flex items-center justify-center font-serif text-lg') do
      plain initials
    end
  end

  def render_info
    div do
      div(class: 'font-extra-bold text-base leading-tight mb-0.5') { @partner.name }
      div(class: 'text-xs text-tertiary leading-snug') do
        parts = [area_text, category_text].compact_blank
        plain parts.join(' · ')
      end
    end
  end

  def render_events_badge
    return unless @event_count.positive?

    div(class: 'text-right') do
      span(class: 'inline-flex items-center bg-primary-light text-foreground text-2xs font-bold rounded-full px-2.5 py-0.5') do
        plain "#{@event_count} #{'event'.pluralize(@event_count)}"
      end
    end
  end

  def initials
    @partner.name.split.first(2).map { |w| w[0] }.join.upcase
  end

  def area_text
    @partner.address&.neighbourhood&.name || @partner.address&.postcode
  end

  def category_text
    @partner.categories.first&.name
  end
end
