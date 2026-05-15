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

    DirectoryPageHero(
      title: @partnership.name,
      kicker: 'Partnership',
      breadcrumb_label: @partnership.name
    )

    div(class: 'container-public') do
      render_description if @partnership.description.present?
      render_stats
      render_partners
      render_events
      render_visit_link
    end
  end

  private

  def render_description
    div(class: 'py-6') do
      p(class: 'text-lg leading-relaxed text-foreground') { @partnership.description }
    end
  end

  def render_stats
    div(class: 'flex gap-3 flex-wrap py-4') do
      stat_chip("#{partner_count} #{'partner'.pluralize(partner_count)}")
      stat_chip("#{event_count} upcoming #{'event'.pluralize(event_count)}")
      stat_chip(@partnership.primary_neighbourhood.name) if @partnership.primary_neighbourhood
    end
  end

  def stat_chip(text)
    span(class: 'inline-flex items-center bg-primary-light text-foreground text-sm font-bold rounded-full px-3 py-1') do
      plain text
    end
  end

  def render_partners
    div(class: 'py-6') do
      h2(class: 'font-serif text-2xl text-foreground mb-4') { 'Partners' }
      div(class: 'flex flex-col') do
        partner_list.each do |partner|
          DirectoryPartnerCard(partner: partner, site: @partnership)
        end
      end
    end
  end

  def render_events
    return if flat_events.empty?

    div(class: 'py-6') do
      h2(class: 'font-serif text-2xl text-foreground mb-4') { 'Upcoming events' }
      flat_events.first(10).each do |event|
        DirectoryEventRow(event: event)
      end
    end
  end

  def render_visit_link
    div(class: 'py-6') do
      a(href: "https://#{@partnership.slug}.placecal.org",
        class: 'inline-flex items-center gap-2 bg-foreground text-background font-bold rounded-full px-5 py-2.5 no-underline hover:bg-tertiary transition-colors') do
        plain "Visit #{@partnership.slug}.placecal.org"
        span { safe('&rarr;') }
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
