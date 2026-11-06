# frozen_string_literal: true

# Tells search engines which partner and event pages changed, so they don't wait for a recrawl.
class IndexNowSubmission
  ENDPOINT = 'https://api.indexnow.org/indexnow'
  # Not a secret: IndexNow proves a host's ownership by that host serving this value.
  KEY = '318c9cc3c1677c7ff1bed469c5ff182e'
  KEY_PATH = '/indexnow-key.txt'
  MAX_URLS = 10_000
  TIMEOUT = 15 # seconds

  # @param since [Time] submit pages changed after this
  def initialize(since:)
    @since = since
  end

  def call
    [nil, *served_sites].each do |site|
      submit(Site.permalink_base_url_for(site), PartnersQuery.new(site:).call.reorder(nil), EventsQuery.new(site:).scope)
    end
  end

  private

  def served_sites
    Site.published.where.not(domain: nil).select(&:served_domain?)
  end

  def submit(base_url, partners, events)
    urls = (partner_urls(base_url, partners) + event_urls(base_url, events)).first(MAX_URLS)
    return if urls.empty?

    response = post(base_url, urls)
    Rails.logger.warn("IndexNow refused #{base_url}: #{response.code}") unless response.success?
  rescue StandardError => e
    Rails.logger.warn("IndexNow failed for #{base_url}: #{e.message}")
  end

  def partner_urls(base_url, partners)
    partners.where(partners: { updated_at: @since.. }).pluck(:slug).uniq.map { |slug| "#{base_url}/partners/#{slug}" }
  end

  # Past event pages are noindexed, so there's nothing to tell search engines about them.
  def event_urls(base_url, events)
    events.where(events: { updated_at: @since.. })
          .where('COALESCE(dtend, dtstart) >= ?', Time.current)
          .reorder(nil)
          .pluck('events.id')
          .uniq
          .map { |id| "#{base_url}/events/#{id}" }
  end

  def post(base_url, urls)
    body = { host: URI(base_url).host, key: KEY, keyLocation: "#{base_url}#{KEY_PATH}", urlList: urls }
    HTTParty.post(ENDPOINT, body: body.to_json, headers: { 'Content-Type' => 'application/json; charset=utf-8' }, timeout: TIMEOUT)
  end
end
