# frozen_string_literal: true

# Serves generated Open Graph share card PNGs (issue #2077).
# Cards are rendered with libvips (see app/services/og_image/) and cached.
class OgImagesController < ApplicationController
  before_action :set_site

  CACHE_TTL = 1.week

  # The pages that get a card of their own, and the key for the name it shows. Only these names
  # are drawn, so nobody can put their own words on a PlaceCal card.
  PAGES = {
    'events' => 'events.index.page_title',
    'partners' => 'partners.index.page_title',
    'news' => 'news.index.page_title',
    'partnerships' => 'activerecord.models.partnership.other',
    'get_in_touch' => 'sites.join.hero.title',
    'our_story' => 'directory.pages.our_story.heading',
    'mcp' => 'directory.pages.mcp.heading',
    'privacy' => 'directory.pages.privacy.document_title',
    'terms_of_use' => 'directory.pages.terms_of_use.document_title',
    'sustainability' => 'directory.pages.sustainability.document_title',
    'accessibility' => 'directory.pages.accessibility.document_title'
  }.freeze

  # GET /events/:id/opengraph.png
  def event
    event = Event.find(params[:id])
    send_card(OgImage::EventCard.new(event), [event.id, event.updated_at.to_i])
  end

  # GET /partners/:id/opengraph.png
  def partner
    partner = Partner.friendly.find(params[:id])
    raise ActiveRecord::RecordNotFound if partner.hidden

    send_card(OgImage::PartnerCard.new(partner), [partner.id, partner.updated_at.to_i])
  end

  # GET /partnerships/:id/opengraph.png
  def partnership
    partnership = Site.where(is_published: true).friendly.find(params[:id])
    send_card(OgImage::PartnershipCard.new(partnership), [partnership.id, partnership.updated_at.to_i])
  end

  # GET /opengraph/:page.png
  def page
    key = PAGES[params[:page]]
    return head :not_found unless key

    send_card(OgImage::PageCard.new(I18n.t(key), site: @site),
              [params[:page], @site&.id, @site&.updated_at.to_i, I18n.locale])
  end

  # GET /opengraph.png — site card on a site subdomain, brand card otherwise
  def default
    if @site
      send_card(OgImage::SiteCard.new(@site), [@site.id, @site.updated_at.to_i])
    else
      send_card(OgImage::GenericCard.new, [])
    end
  end

  private

  def send_card(card, key_parts)
    key = ['og_image', OgImage::VERSION, card.class.name.demodulize.underscore, *key_parts].join('/')
    png = Rails.cache.fetch(key, expires_in: CACHE_TTL) { card.to_png }

    expires_in 1.day, public: true
    send_data png, type: 'image/png', disposition: 'inline'
  end
end
