# frozen_string_literal: true

class Views::Directory::Home < Views::Base
  include Views::Directory::Concerns::FlattensEvents

  prop :partnerships, _Interface(:each)
  prop :recent_partners, _Interface(:each)
  prop :upcoming_events, _Interface(:each)
  prop :stats, Hash
  prop :partner_event_counts, Hash, default: -> { {} }
  prop :partner_locations, _Interface(:each), default: -> { [] }
  prop :jump_neighbourhoods, _Interface(:each), default: -> { [] }

  def view_template
    content_for(:description) { t('directory.home.description') }

    Directory::Hero(
      title: t('directory.home.hero_title'),
      subtitle: t('directory.home.hero_subtitle'),
      search_path: partners_path,
      partner_locations: @partner_locations,
      jump_neighbourhoods: @jump_neighbourhoods
    )

    Directory::StatsStrip(stats: [
                            { value: @stats[:partnerships], label: ::Partnership.model_name.human(count: 2), icon: :partnership },
                            { value: @stats[:partners], label: ::Partner.model_name.human(count: 2), icon: :partner },
                            { value: @stats[:events], label: t('directory.home.stats.events'), icon: :event },
                            { value: @stats[:neighbourhoods], label: ::Neighbourhood.model_name.human(count: 2), icon: :neighbourhood }
                          ])

    render_partnerships_section
    render_activity_section
    render_cta_section
  end

  private

  def render_partnerships_section
    section(class: 'py-5') do
      div(class: 'container-public') do
        div(class: 'flex justify-between items-baseline flex-wrap gap-2') do
          div do
            div(class: 'allcaps-label text-tertiary') { t('directory.home.partnerships.kicker') }
            h2(class: 'font-serif font-regular text-section text-foreground') { t('directory.home.partnerships.heading') }
          end
          a(href: partnerships_path,
            class: 'btn-primary-outline transition-colors') do
            plain t('directory.home.partnerships.see_all')
            span { safe('&rarr;') }
          end
        end
        div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4 mt-5 lg:mt-0') do
          @partnerships.first(6).each do |partnership|
            Directory::PartnershipCard(partnership: partnership)
          end
        end
      end
    end
  end

  def render_activity_section
    section(class: 'py-10 bg-home-background') do
      div(class: 'container-public') do
        div(class: 'grid lg:grid-cols-2 gap-8') do
          render_recent_partners
          render_upcoming_events
        end
      end
    end
  end

  def render_recent_partners
    div do
      div(class: 'allcaps-label text-tertiary') { t('directory.home.activity.kicker') }
      h2(class: 'font-serif font-regular text-section text-foreground mb-4') { t('directory.home.activity.heading') }
      div(class: 'flex flex-col gap-2') do
        partners = @recent_partners.first(5)
        partners.each do |partner|
          Directory::PartnerRow(partner: partner, event_count: @partner_event_counts[partner.id] || 0)
        end
      end
      div(class: 'mt-4') do
        a(href: partners_path,
          class: 'inline-flex items-center gap-2 bg-home-background border-2 border-primary rounded-full px-5 py-2 text-detail font-bold text-foreground no-underline hover:bg-primary transition-colors') do
          plain t('directory.home.activity.browse_all')
          span { safe('&rarr;') }
        end
      end
    end
  end

  def render_upcoming_events
    div do
      div(class: 'allcaps-label text-tertiary') { t('directory.home.events.kicker') }
      h2(class: 'font-serif font-regular text-section text-foreground mb-4') { t('directory.home.events.heading') }
      div do
        flat_events.first(5).each do |event|
          Directory::EventRow(event: event)
        end
      end
      div(class: 'mt-4') do
        a(href: events_path,
          class: 'inline-flex items-center gap-2 bg-home-background border-2 border-primary rounded-full px-5 py-2 text-detail font-bold text-foreground no-underline hover:bg-primary transition-colors') do
          plain t('directory.home.events.filter_by_place')
          span { safe('&rarr;') }
        end
      end
    end
  end

  def render_cta_section
    section(class: 'py-10') do
      div(class: 'container-public grid md:grid-cols-2 gap-4') do
        render_cta_card(
          heading: t('directory.home.cta.what_is.heading'),
          body: t('directory.home.cta.what_is.body'),
          link_text: t('directory.home.cta.what_is.link'),
          link_path: our_story_path,
          head_class: 'bg-secondary'
        )
        render_cta_card(
          heading: t('directory.home.cta.run.heading'),
          body: t('directory.home.cta.run.body'),
          link_text: t('directory.home.cta.run.link'),
          link_path: get_in_touch_path,
          head_class: 'bg-primary'
        )
      end
    end
  end

  def render_cta_card(heading:, body:, link_text:, link_path:, head_class:)
    div(class: 'flex flex-col rounded-card overflow-hidden') do
      div(class: "#{head_class} px-5") do
        h3(class: 'font-serif font-regular text-card', style: 'color: #43392f') { heading }
      end
      div(class: 'bg-home-background-3 px-5 py-4 flex-1') do
        p(class: 'text-detail leading-relaxed text-tertiary mb-4') { body }
        a(href: link_path,
          class: 'btn-dark-outline transition-colors') do
          plain link_text
        end
      end
    end
  end
end
