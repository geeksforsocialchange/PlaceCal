# frozen_string_literal: true

class Components::Directory::PartnerMini < Components::Directory::Base
  prop :partner, ::Partner
  prop :event_count, Integer, default: 0

  def view_template
    a(href: partner_path(@partner),
      class: 'grid grid-cols-[var(--size-avatar-sm)_1fr] gap-3 items-start py-3 px-3 rounded-card border border-rules no-underline text-foreground hover:bg-home-background-3 transition-colors') do
      render_avatar
      div do
        div(class: 'flex items-start justify-between gap-2') do
          span(class: 'font-extra-bold text-sm leading-tight') { @partner.name }
          render_event_badge
        end
        div(class: 'text-xs text-tertiary mt-0.5') { @partner.location_name } if @partner.location_name.present?
        div(class: 'text-xs text-tertiary mt-0.5') { @partner.categories.first(2).map(&:name).join(' · ') } if @partner.categories.any?
      end
    end
  end

  private

  def render_avatar
    if @partner.image?
      img(src: @partner.image.standard.url, alt: @partner.name, class: 'w-(--size-avatar-sm) h-(--size-avatar-sm) rounded-card object-cover')
    else
      initials = @partner.name.split.first(2).map { |w| w[0] }.join.upcase
      div(class: 'w-(--size-avatar-sm) h-(--size-avatar-sm) rounded-full bg-home-background-3 flex items-center justify-center font-serif text-lg text-tertiary') do
        plain initials
      end
    end
  end

  def render_event_badge
    return unless @event_count.positive?

    span(class: 'inline-flex items-center bg-primary text-foreground text-2xs font-bold rounded-full px-2 py-0.5 whitespace-nowrap') do
      plain "#{@event_count} #{'event'.pluralize(@event_count)}"
    end
  end
end
