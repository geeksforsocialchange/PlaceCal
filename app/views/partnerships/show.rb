# frozen_string_literal: true

# TODO(#3163): Move to app/directory/views/partnerships/show.rb
class Views::Partnerships::Show < Views::Base
  prop :partnership, ::Site
  prop :partners, _Interface(:each)
  prop :upcoming_events, _Interface(:each)
  prop :site, _Nilable(::Site), default: nil

  def view_template
    content_for(:title) { @partnership.name }
    content_for(:description) { @partnership.description.presence || "#{@partnership.name} — a PlaceCal partnership bringing together community partners and events." }

    render_hero
    div(class: 'container-public py-6') do
      render_partners
      render_events
    end
  end

  private

  def render_hero
    section(class: 'bg-foreground', style: 'color: var(--color-background)') do
      div(class: 'container-public py-8') do
        render_breadcrumb
        p(class: 'allcaps-label mb-1 opacity-60') { 'Partnership' }
        h1(class: 'font-serif font-regular text-hero leading-hero mb-3') do
          plain @partnership.name
        end
        p(class: 'text-base leading-relaxed max-w-[620px] mb-5 opacity-80') { @partnership.description } if @partnership.description.present?
        div(class: 'flex flex-wrap items-center gap-3') do
          render_visit_button
          render_stat_chips
        end
      end
    end
  end

  def render_breadcrumb
    nav(class: 'text-sm mb-3', style: 'color: var(--color-background)', aria_label: 'Breadcrumb') do
      a(href: root_path, class: 'no-underline hover:underline opacity-70', style: 'color: inherit') { 'Directory' }
      span(class: 'mx-1.5 opacity-60') { safe('›') }
      a(href: partnerships_path, class: 'no-underline hover:underline opacity-70', style: 'color: inherit') { 'Partnerships' }
      span(class: 'mx-1.5 opacity-60') { safe('›') }
      span(class: 'opacity-90') { @partnership.name }
    end
  end

  def render_visit_button
    a(href: "https://#{@partnership.slug}.placecal.org",
      class: 'inline-flex items-center gap-2 bg-primary text-foreground font-bold rounded-full px-5 py-2 no-underline hover:brightness-110 transition-all') do
      safe('&#8599;')
      plain "Visit #{@partnership.slug}.placecal.org"
    end
  end

  def render_stat_chips
    chip("#{partner_count} #{'partner'.pluralize(partner_count)}")
    chip("#{event_count} #{'event'.pluralize(event_count)} this month")
    chip(@partnership.primary_neighbourhood.name) if @partnership.primary_neighbourhood
  end

  def chip(text)
    span(class: 'inline-flex items-center text-sm font-bold rounded-full px-3 py-1', style: 'background: rgba(91,78,70,0.8); color: var(--color-background)') do
      plain text
    end
  end

  def render_partners
    div(class: 'py-4') do
      h2(class: 'allcaps-label text-tertiary mb-4') { 'Partners in this partnership' }
      div(class: 'flex flex-col') do
        partner_list.each do |partner|
          Directory::PartnerCard(partner: partner, site: @partnership)
        end
      end
    end
  end

  def render_events
    return if flat_events.empty?

    div(class: 'py-6') do
      h2(class: 'allcaps-label text-tertiary mb-4') { 'Upcoming events' }
      flat_events.first(10).each do |event|
        Directory::EventRow(event: event)
      end
    end
  end

  def partner_list
    @partner_list ||= if @partners.respond_to?(:each_pair)
                        @partners.values.flatten
                      else
                        Array(@partners)
                      end
  end

  def partner_count
    partner_list.size
  end

  def event_count
    flat_events.size
  end

  def flat_events
    @flat_events ||= if @upcoming_events.respond_to?(:each_pair)
                       @upcoming_events.values.flatten
                     else
                       Array(@upcoming_events)
                     end
  end
end
