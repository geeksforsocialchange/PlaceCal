# frozen_string_literal: true

class Views::Sites::Directory < Views::Base
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { 'PlaceCal Directory' }
    content_for(:image) { site.og_image }
    content_for(:description) { 'Browse all partners, events, and partnerships on PlaceCal' }

    Hero('PlaceCal Directory', 'A curated social network for the real world')

    render_stats
    render_recent_partnerships
    render_recent_partners
  end

  private

  def render_stats
    section(class: 'region region__mission') do
      div(class: 'c c--narrow') do
        p(class: 'p--big', style: 'text-align: center') do
          plain 'With '
          strong { number_with_delimiter(stats[:partnerships]) }
          plain ' partnerships helping '
          strong { number_with_delimiter(stats[:partners]) }
          plain ' community groups list '
          strong { number_with_delimiter(stats[:events]) }
          plain ' events this month'
        end

        div(style: 'text-align: center; margin-top: 1.5rem') do
          link_to 'Browse events', events_path, class: 'btn btn--lg btn--alt'
          plain ' '
          link_to 'Browse partners', partners_path, class: 'btn btn--lg btn--alt'
        end
      end
    end
  end

  def render_recent_partnerships
    return unless recent_partnerships.any?

    section(class: 'region') do
      div(class: 'c') do
        h2(class: 'udl udl--fw allcaps') { 'Partnerships' }
        ul(class: 'partners reset two-col') do
          recent_partnerships.each do |partnership|
            PartnershipPreview(
              partnership: partnership,
              partner_count: partnership_partner_counts[partnership.id] || 0
            )
          end
        end
        p do
          link_to 'View all partnerships', partnerships_path, class: 'btn btn--alt'
        end
      end
    end
  end

  def render_recent_partners
    return unless recent_partners.any?

    section(class: 'region') do
      div(class: 'c') do
        h2(class: 'udl udl--fw allcaps') { 'Recently added partners' }
        ul(class: 'partners reset two-col') do
          recent_partners.each do |partner|
            PartnerPreview(partner: partner, site: site)
          end
        end
        p do
          link_to 'View all partners', partners_path, class: 'btn btn--alt'
        end
      end
    end
  end

  def stats
    @stats ||= {
      partnerships: ::Partnership.joins(:partners).where(partners: { hidden: false }).distinct.count,
      partners: ::Partner.visible.count,
      events: ::Event.for_month(Time.zone.today).count
    }
  end

  def recent_partnerships
    @recent_partnerships ||= ::Partnership
                             .joins(:partners)
                             .where(partners: { hidden: false })
                             .distinct
                             .order(created_at: :desc)
                             .limit(6)
  end

  def partnership_partner_counts
    @partnership_partner_counts ||= ::PartnerTag
                                    .joins(:partner)
                                    .where(partners: { hidden: false })
                                    .joins(:tag)
                                    .where(tags: { type: 'Partnership' })
                                    .group(:tag_id)
                                    .count
  end

  def recent_partners
    @recent_partners ||= ::Partner.visible.order(created_at: :desc).limit(6)
  end
end
