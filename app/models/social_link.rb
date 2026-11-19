# frozen_string_literal: true

# A partner's profile URL on a social network, with the platform recognised from the URL.
class SocialLink
  PLATFORMS = {
    facebook: { hosts: %w[facebook.com fb.com], icon: :contact_facebook },
    instagram: { hosts: %w[instagram.com], icon: :contact_instagram },
    bluesky: { hosts: %w[bsky.app], icon: :contact_bluesky },
    tiktok: { hosts: %w[tiktok.com], icon: :contact_tiktok },
    youtube: { hosts: %w[youtube.com youtu.be], icon: :contact_youtube },
    linkedin: { hosts: %w[linkedin.com], icon: :contact_linkedin },
    threads: { hosts: %w[threads.net threads.com], icon: :contact_threads },
    x: { hosts: %w[x.com twitter.com], icon: :contact_x }
  }.freeze

  MASTODON_ICON = :contact_mastodon
  LINK_ICON = :link

  # Looser than URI.parse, which rejects addresses with accented letters
  URL_PARTS = %r{\Ahttps?://(?<host>[^/?#\s:@]+)(?::\d+)?(?<path>/[^?#\s]*)?(?:\?(?<query>[^#\s]*))?(?:#\S*)?\z}i

  # Any fediverse server: /@name, or /@name@home.server for a remote account
  FEDIVERSE_PATH = %r{\A/@([\w.-]+)(?:@([\w.-]+\.[a-z]{2,}))?/?\z}i
  HANDLE_SEGMENT = %r{\A/@?([\w.-]+)/?\z}

  attr_reader :url

  def self.valid_url?(url)
    url.to_s.match?(URL_PARTS)
  end

  # Platform names by host, for the admin form to recognise links as they're typed.
  def self.detection_rules
    {
      hosts: PLATFORMS.flat_map { |platform, info| info[:hosts].map { [it, platform_name(platform)] } }.to_h,
      fediverse: platform_name(:mastodon)
    }
  end

  def self.platform_name(platform)
    I18n.t("directory.contact.networks.#{platform}")
  end

  def initialize(url)
    @url = url.to_s
  end

  # @return [Symbol] a PLATFORMS key, :mastodon, or :link for anything else
  def platform
    @platform ||= detect_platform
  end

  def name
    platform == :link ? host : self.class.platform_name(platform)
  end

  def icon
    return PLATFORMS[platform][:icon] if PLATFORMS.key?(platform)

    platform == :mastodon ? MASTODON_ICON : LINK_ICON
  end

  # @return [String, nil] the account name, when the URL makes it obvious
  def handle
    @handle ||= derive_handle
  end

  # The handle, or the address without its scheme
  def label
    handle || display_url
  end

  def known_platform?
    platform != :link
  end

  def host
    parts&.[](:host).to_s.downcase.delete_prefix('www.')
  end

  def to_s = url

  private

  def parts
    return @parts if defined?(@parts)

    @parts = url.match(URL_PARTS)
  end

  def path
    parts&.[](:path).to_s
  end

  def query
    parts&.[](:query)
  end

  def detect_platform
    return :link unless parts

    found = PLATFORMS.find { |_, info| info[:hosts].any? { host == it || host.end_with?(".#{it}") } }
    return found.first if found
    return :mastodon if path.match?(FEDIVERSE_PATH)

    :link
  end

  def derive_handle
    return if parts.nil? || query.present?

    case platform
    when :mastodon then mastodon_handle
    when :bluesky then path[%r{\A/profile/([^/]+)/?\z}, 1]
    when :facebook then path[HANDLE_SEGMENT, 1]&.then { it unless it.end_with?('.php') }
    when :youtube then path[%r{\A/@([\w.-]+)/?\z}, 1]&.then { "@#{it}" }
    when :link, :linkedin then nil
    else path[HANDLE_SEGMENT, 1]&.then { "@#{it}" }
    end
  end

  def mastodon_handle
    account, server = path.match(FEDIVERSE_PATH).captures
    "@#{account}@#{server || host}"
  end

  def display_url
    return url unless parts

    shown = "#{host}#{path.delete_suffix('/')}"
    query.present? ? "#{shown}?#{query}" : shown
  end
end
