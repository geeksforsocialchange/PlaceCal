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
        UI::Cluster(gap: :sm, justify: :between, align: :baseline) do
          div do
            div(class: 'allcaps-label text-tertiary') { t('directory.home.partnerships.kicker') }
            UI::Heading() { t('directory.home.partnerships.heading') }
          end
          UI::Button(variant: :outline, href: partnerships_path) do
            plain t('directory.home.partnerships.see_all')
            span { safe('&rarr;') }
          end
        end
        UI::Grid(cols: { md: 2, lg: 3 }, class: 'mt-5 lg:mt-0') do
          @partnerships.first(6).each do |partnership|
            Directory::PartnershipCard(partnership:)
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
    UI::Stack(gap: :md) do
      activity_heading(t('directory.home.activity.kicker'), t('directory.home.activity.heading'))
      UI::Stack(gap: :sm) do
        partners = @recent_partners.first(5)
        partners.each do |partner|
          Directory::PartnerRow(partner:, event_count: @partner_event_counts[partner.id] || 0)
        end
      end
      div do
        UI::Button(variant: :outline, href: partners_path) do
          plain t('directory.home.activity.browse_all')
          span { safe('&rarr;') }
        end
      end
    end
  end

  def render_upcoming_events
    UI::Stack(gap: :md) do
      activity_heading(t('directory.home.events.kicker'), t('directory.home.events.heading'))
      div do
        flat_events.first(5).each do |event|
          Directory::EventRow(event:)
        end
      end
      div do
        UI::Button(variant: :outline, href: events_path) do
          plain t('directory.home.events.filter_by_place')
          span { safe('&rarr;') }
        end
      end
    end
  end

  # :lg is the base heading's top margin.
  def activity_heading(kicker, heading)
    UI::Stack(gap: :lg) do
      div(class: 'allcaps-label text-tertiary') { kicker }
      UI::Heading() { heading }
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
        h3(class: 'font-serif font-regular text-card', style: 'color: var(--color-foreground-dark)') { heading }
      end
      div(class: 'bg-home-background-3 px-5 py-4 flex-1') do
        p(class: 'text-detail leading-relaxed text-tertiary mb-4') { body }
        UI::Button(variant: :dark_outline, href: link_path) { link_text }
      end
    end
  end
end
