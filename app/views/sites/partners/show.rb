# frozen_string_literal: true

class Views::Sites::Partners::Show < Views::Base
  include Phlex::Rails::Helpers::SelectTag
  include Phlex::Rails::Helpers::OptionsForSelect

  register_value_helper :partner_service_area_text

  prop :partner, Partner, reader: :private
  prop :site, _Nilable(::Site), reader: :private
  prop :current_day, Date, reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :events, _Interface(:each), reader: :private
  prop :period, _Nilable(String), reader: :private
  prop :sort, _Nilable(String), reader: :private
  prop :repeating, _Nilable(String), reader: :private
  prop :no_event_message, _Nilable(String), reader: :private
  prop :paginator, _Nilable(_Boolean), reader: :private
  prop :date_period, _Nilable(String), reader: :private, default: nil
  prop :show_monthly, _Boolean, reader: :private, default: true
  prop :containing_sites, _Nilable(_Interface(:each)), reader: :private, default: nil
  # Days-based "Show more days" paging for the events browser (see
  # PartnersController#show). `events_total_count`/`events_total_days` are
  # the whole upcoming set after the repeating filter but before the days
  # limit is applied, so the header can report a total independent of what's
  # actually on screen.
  prop :days, Integer, reader: :private, default: 4
  prop :more_days, Integer, reader: :private, default: 0
  prop :events_total_count, _Nilable(Integer), reader: :private, default: nil
  prop :events_total_days, _Nilable(Integer), reader: :private, default: nil

  def view_template
    set_content_for_tags
    render_local_layout
    render_meta_section
    render_page_actions
  end

  private

  def set_content_for_tags
    content_for(:title) { title_with_place }
    content_for(:canonical) { partner.permalink }
    content_for(:image) { partner_og_image_url(partner) }
    content_for(:image_alt) { t('og_image.alt.partner', name: partner.name) }
    content_for(:description) { partner.summary } if partner.summary
    # Built from the directory apex, not request.base_url, so the JSON-LD @id
    # names the same URL as the canonical tag above — the structured data must
    # reinforce the canonical entity, not contradict it per-subdomain.
    content_for(:json_ld) { safe(partner.to_json_ld(base_url: ::Site::DIRECTORY_URL).to_json) }
  end

  # "Partner Name, Place" — the locality makes the <title> match how people
  # actually search ("X in Y"). Neighbourhood name first (most local), city
  # as fallback; service-area-only partners just get their name. Skipped when
  # the name already contains the place ("Moss Side Powerhouse Library, Moss
  # Side" reads clunky in search results and adds nothing).
  def title_with_place
    place = partner.address&.neighbourhood&.name.presence || partner.address&.city.presence
    return partner.name if place.nil? || partner.name.downcase.include?(place.downcase)

    "#{partner.name}, #{place}"
  end

  def render_partner_description
    if partner.summary
      div(class: 'partner-details__description text-xl leading-snug') do
        content_tag(:p, partner.summary)
      end
    end
    return if partner.description_html.blank?

    div do
      raw safe(partner.description_html.to_s)
    end
  end

  # ── Local site layout ──

  def render_local_layout
    div do
      Shared::Hero(partner.name, site.tagline, section: t('partners.show.section'),
                                               back: [t('partners.show.back_to_index'), partners_path])

      div(class: 'container-public mb-32') do
        Sites::Breadcrumb(
          trail: [[t('navigation.site.partners'), partners_path], [partner.name, partner_path(partner)]],
          site_name: site.name
        )

        render_partner_details
        render_children
        render_events_section
      end
      # Under the whole box, not in the sidebar, so a theme can run it full width
      Shared::Map(points: map, compact: true) unless site.core_theme?
    end
  end

  def render_partner_details
    div(class: 'partner-details grid grid-areas-partner-details') do
      div(class: 'partner-details__main grid-area-main') do
        render_partner_description
        render_contact_and_address
      end
      aside(class: 'partner-details__aside grid-area-right') do
        render_partner_image
        Shared::Map(points: map, compact: true) if site.core_theme?
        render_opening_times
        render_accessibility
      end
    end
  end

  # h2, not h3: these are the first headings under the page's h1.
  def render_contact_and_address
    UI::RuledHeading(caps: true, rule: :full, class: 'text-xl my-5.5') { t('partners.show.contact_heading') }
    Shared::ContactDetails(partner:, social_labels: site&.core_theme? ? :handle : :network)

    render_address
    render_family_sentence
  end

  # view_context.link_to, not the registered output helper: the helper writes
  # straight to the buffer, ahead of the sentence the links are interpolated into.
  def render_family_sentence
    if visible_parent
      div(class: 'partner__family text-sm leading-normal') do
        raw(t('partners.show.part_of_html', parent: view_context.link_to(visible_parent.name, partner_path(visible_parent))))
      end
    elsif visible_children.any?
      places = safe_join(visible_children.map { |child| view_context.link_to(child.name, partner_path(child)) }, ', ')
      div(class: 'partner__family text-sm leading-normal') do
        raw(t('partners.show.children_html', name: partner.name, places:))
      end
    end
  end

  def visible_parent
    return @visible_parent if defined?(@visible_parent)

    @visible_parent = partner.parent unless partner.parent&.hidden
  end

  def visible_children
    @visible_children ||= partner.children.visible.includes(:address).order(:name).to_a
  end

  def render_address
    UI::RuledHeading(caps: true, rule: :full, class: 'text-xl my-5.5') { t('partners.show.address_heading') }
    if partner.service_areas?
      p(class: 'place_info__service_area') do
        raw(t('partners.show.service_area_html', areas: partner_service_area_text(partner)))
      end
    end
    Shared::Address(address: partner.address) if partner.address
  end

  def render_partner_image
    return unless partner.image?

    div(class: 'partner-details__image text-center my-6 print:hidden') do
      img(
        src: partner.image.standard.url,
        srcset: "#{partner.image.standard.url} 1x, #{partner.image.retina.url} 2x",
        alt: t('partners.show.image_alt', name: partner.name),
        class: 'map--single max-w-full'
      )
    end
  end

  def render_opening_times
    times = partner.human_readable_opening_times
    return unless times.any?

    br
    UI::RuledHeading(caps: true, rule: :full, class: 'text-xl my-5.5') { t('partners.show.opening_times_heading') }
    ul(class: 'opening_times reset') do
      times.each do |slot|
        li { slot }
      end
    end
  end

  def render_accessibility
    return if partner.accessibility_info_html.blank?

    br
    UI::RuledHeading(caps: true, rule: :full, class: 'text-xl my-5.5', id: 'accessibility-info') { t('partners.show.accessibility_heading') }
    details(class: 'accessibility_info') do
      summary { t('partners.show.accessibility_summary') }
      raw safe(partner.accessibility_info_html.to_s)
    end
  end

  def render_children
    visible_children.each do |place|
      hr

      h2(class: 'mb-2') { link_to place.name, partner_path(place), class: 'inline-block pb-2 border-b-3 border-secondary no-underline' }
      div(class: 'grid gap-x-4.5 lg:grid-cols-2') do
        div do
          raw safe(place.summary_html.to_s) if place.summary_html.present?
        end
        div do
          if place.address
            UI::RuledHeading(caps: true, rule: :full, class: 'text-xl my-5.5') { t('partners.show.address_heading') }
            div(class: 'text-sm leading-normal') do
              Shared::Address(address: place.address)
            end
          end
          UI::RuledHeading(caps: true, rule: :full, class: 'text-xl my-5.5') { t('partners.show.place_contact_heading') }
          div(class: 'text-sm leading-normal') do
            Shared::ContactDetails(partner: place)
          end
        end
      end
    end
  end

  def render_events_section
    turbo_frame_tag 'events-browser', data: { turbo_action: 'advance' } do
      render_events_header if events_total_count&.positive?
      render_events_paginator if paginator

      if events.any?
        Sites::EventList(
          events:,
          period:,
          primary_neighbourhood: site.primary_neighbourhood,
          show_neighbourhoods: site.show_neighbourhoods?,
          badge_zoom_level: site.badge_zoom_level&.to_s,
          site_tagline: site.tagline,
          context_partner: partner
        )
      else
        p { em { no_event_message || empty_period_message } }
      end
      render_events_actions
    end
  end

  # Closes the event browser with the next page of days, inside the frame it pages.
  def render_events_actions
    return unless more_days.positive?

    div(class: 'partner-events__actions') { render_show_more_days }
  end

  def render_events_header
    div(class: 'partner-events__header') do
      h2(class: 'partner-events__heading') { t('partners.show.upcoming_events') }
      span(class: 'partner-events__count') { events_count_text }
      render_repeating_filter
    end
  end

  def events_count_text
    events_text = t('partners.show.events_count_events', count: events_total_count)
    days_text = t('partners.show.events_count_days', count: events_total_days)
    "#{events_text} #{days_text}"
  end

  def render_repeating_filter
    div(class: 'partner-events__repeating-filter', data: { controller: 'filters' }) do
      form_tag('', method: :get, class: 'partner-events__repeating-form', enforce_utf8: false,
                   data: { turbo_frame: 'events-browser', turbo_action: 'advance',
                           filters_target: 'form', action: 'change->filters#submit' }) do
        hidden_field_tag(:days, days, id: nil)
        hidden_field_tag(:period, period, id: nil) if period.present?
        hidden_field_tag(:sort, sort, id: nil) if sort.present?
        # The select is wrapped in its label (implicit association) rather
        # than paired by id: the paginator's own repeating radios reuse
        # "repeating"-derived ids, and this form can render alongside them.
        label do
          plain t('partners.show.show_label')
          select_tag(:repeating, class: 'partner-events__repeating', id: nil) do
            options_for_select(repeating_options, repeating)
          end
        end
      end
    end
  end

  def repeating_options
    %w[on off only].map { |value| [t("filters.repeating.#{value}"), value] }
  end

  def render_show_more_days
    count = [more_days, 4].min
    a(href: show_more_days_url, class: 'partner-events__more', data: { turbo_frame: 'events-browser' }) do
      t('partners.show.show_more_days', count:)
    end
  end

  def show_more_days_url
    url_params = { days: days + 4 }
    url_params[:period] = period if period.present?
    url_params[:sort] = sort if sort.present?
    url_params[:repeating] = repeating if repeating.present?
    partner_path(partner, **url_params)
  end

  def render_events_paginator
    path = "partners/#{partner.slug}/events"
    today = Time.zone.today
    filter_period = date_period || period
    div(class: 'paginator', id: 'paginator') do
      Sites::Timeline(
        pointer: current_day,
        period:,
        date_period:,
        sort:,
        repeating:,
        path:,
        show_upcoming: true
      )
      div(class: 'paginator__actions') do
        today_url = "/#{path}/#{today.year}/#{today.month}/#{today.day}?period=#{filter_period}&sort=#{sort}&repeating=#{repeating}#paginator"
        Sites::EventFilter(
          pointer: current_day,
          period: filter_period,
          sort:,
          repeating:,
          today_url:,
          today: current_day == today,
          show_monthly:
        )
      end
    end
  end

  def empty_period_message
    case period
    when 'day' then t('partners.show.no_events_day')
    when 'week' then t('partners.show.no_events_week')
    when 'month' then t('partners.show.no_events_month')
    else t('partners.show.no_events_upcoming')
    end
  end

  # Page actions row (Components::Sites::PageActions, #3368): back to the index,
  # the feed, then the export when there is something to export.
  def render_page_actions
    links = [[t('partners.show.go_back'), partners_path],
             [t('partners.show.subscribe_ical', name: partner.name), partner_url(partner, protocol: :webcal, format: :ics)]]
    links << [t('events.csv_export.link'), partner_url(partner, format: :csv)] if events.any?
    Sites::PageActions(links:)
  end

  # Meta carries the permalink alone; the feed and export are page actions.
  def render_meta_section
    Sites::Meta("/partners/#{partner.id}")
  end
end
