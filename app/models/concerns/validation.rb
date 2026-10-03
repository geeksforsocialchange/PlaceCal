# frozen_string_literal: true

module Validation
  # Simple URL format check — validates structure, not reachability.
  URL_REGEX = %r{\Ahttps?://[^\s]+\z}i.freeze

  # Calendar sources also accept webcal:// scheme
  CALENDAR_URL_REGEX = %r{\A(https?|webcal)://[^\s]+\z}i.freeze

  TWITTER_REGEX = /\A@?(\w){1,15}\z/.freeze

  # https://blog.jstassen.com/2016/03/code-regex-for-instagram-username-and-hashtags/
  INSTAGRAM_REGEX = /\A([A-Za-z0-9_](?:(?:[A-Za-z0-9_]|(?:\.(?!\.))){0,28}(?:[A-Za-z0-9_]))?)\z/.freeze

  FACEBOOK_REGEX = /\A(\w){1,50}\z/.freeze

  UK_NUMBER_REGEX = /\A(?:(?:\(?(?:0(?:0|11)\)?[\s-]?\(?|\+)44\)?[\s-]?(?:\(?0\)?[\s-]?)?)|(?:\(?0))(?:(?:\d{5}\)?[\s-]?\d{4,5})|(?:\d{4}\)?[\s-]?(?:\d{5}|\d{3}[\s-]?\d{3}))|(?:\d{3}\)?[\s-]?\d{3}[\s-]?\d{3,4})|(?:\d{2}\)?[\s-]?\d{4}[\s-]?\d{4}))(?:[\s-]?(?:x|ext\.?|\#)\d{3,4})?\z/.freeze

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i.freeze

  # Literal addresses only; hostnames are vetted after DNS resolution at fetch time.
  def self.private_ip?(url)
    OutboundUrlGuard.blocked_literal?(url)
  end
end
