# frozen_string_literal: true

# TODO(#3163): Move to app/directory/views/partnerships/show.rb
class Views::Partnerships::Show < Views::Base
  prop :partnership, ::Site
  prop :partners, _Interface(:each)
  prop :upcoming_events, _Interface(:each)
  prop :site, _Nilable(::Site), default: nil

  def view_template
    content_for(:title) { @partnership.name }

    Hero(@partnership.name, 'Partnership')

    div(class: 'c') do
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
      p { @partnership.description }
    end
  end

  def render_stats
    div(class: 'flex gap-4 flex-wrap py-4') do
      stat_chip("#{partner_count} partners")
      stat_chip("#{event_count} upcoming events")
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
      h2 { 'Partners' }
      if @partners.respond_to?(:each_pair)
        @partners.each_value do |group|
          Array(group).each { |partner| render_partner(partner) }
        end
      else
        @partners.each { |partner| render_partner(partner) }
      end
    end
  end

  def render_partner(partner)
    PartnerPreview(partner: partner, site: @partnership)
  end

  def render_events
    return if flat_events.empty?

    div(class: 'py-6') do
      h2 { 'Upcoming events' }
      flat_events.first(10).each do |event|
        DirectoryEventRow(event: event)
      end
    end
  end

  def render_visit_link
    div(class: 'py-6') do
      a(href: "https://#{@partnership.slug}.placecal.org",
        class: 'inline-flex items-center gap-2 bg-primary text-foreground font-bold rounded-full px-5 py-2.5 no-underline hover:bg-primary-light transition-colors') do
        plain "Visit #{@partnership.slug}.placecal.org"
        span { safe('&rarr;') }
      end
    end
  end

  def partner_count
    if @partners.respond_to?(:count)
      @partners.respond_to?(:each_pair) ? @partners.values.flatten.count : @partners.count
    else
      0
    end
  end

  def event_count
    flat_events.count
  end

  def flat_events
    @flat_events ||= if @upcoming_events.respond_to?(:each_pair)
                       @upcoming_events.values.flatten
                     else
                       Array(@upcoming_events)
                     end
  end
end
