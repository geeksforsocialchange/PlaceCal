# frozen_string_literal: true

module Validation
  # Simple URL format check — validates structure, not reachability.
  # Does NOT block private IPs (use PRIVATE_IP_RANGES for that).
  URL_REGEX = %r{\Ahttps?://[^\s]+\z}i.freeze

  # Calendar sources also accept webcal:// scheme
  CALENDAR_URL_REGEX = %r{\A(https?|webcal)://[^\s]+\z}i.freeze

  # RFC 1918 / loopback / link-local ranges that should not be used
  # as calendar source URLs (SSRF prevention).
  PRIVATE_IP_RANGES = [
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('127.0.0.0/8'),
    IPAddr.new('169.254.0.0/16'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('192.168.0.0/16')
  ].freeze

  TWITTER_REGEX = /\A@?(\w){1,15}\z/.freeze

  # https://blog.jstassen.com/2016/03/code-regex-for-instagram-username-and-hashtags/
  INSTAGRAM_REGEX = /\A([A-Za-z0-9_](?:(?:[A-Za-z0-9_]|(?:\.(?!\.))){0,28}(?:[A-Za-z0-9_]))?)\z/.freeze

  FACEBOOK_REGEX = /\A(\w){1,50}\z/.freeze

  UK_NUMBER_REGEX = /\A(?:(?:\(?(?:0(?:0|11)\)?[\s-]?\(?|\+)44\)?[\s-]?(?:\(?0\)?[\s-]?)?)|(?:\(?0))(?:(?:\d{5}\)?[\s-]?\d{4,5})|(?:\d{4}\)?[\s-]?(?:\d{5}|\d{3}[\s-]?\d{3}))|(?:\d{3}\)?[\s-]?\d{3}[\s-]?\d{3,4})|(?:\d{2}\)?[\s-]?\d{4}[\s-]?\d{4}))(?:[\s-]?(?:x|ext\.?|\#)\d{3,4})?\z/.freeze

  EMAIL_REGEX = /\A([\w+-].?)+@[a-z\d-]+(\.[a-z]+)*\.[a-z]+\z/i.freeze

  # Check whether a URL points to a private/reserved IP address.
  # Used to prevent SSRF when fetching calendar sources.
  def self.private_ip?(url)
    host = URI.parse(url).host
    return false unless host

    ip = IPAddr.new(host)
    PRIVATE_IP_RANGES.any? { |range| range.include?(ip) }
  rescue URI::InvalidURIError, IPAddr::InvalidAddressError
    # Not an IP literal — domain names are fine
    false
  end
end
