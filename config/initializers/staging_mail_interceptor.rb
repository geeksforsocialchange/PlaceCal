# frozen_string_literal: true

# Staging runs against a copy of production data, so its database holds
# real partner email addresses. This interceptor makes it impossible for
# staging to email a real person: any recipient outside the allowlisted
# domains is dropped and, if nobody safe remains, the message is redirected
# to the fallback inbox with the original recipients recorded in a header.
class StagingMailInterceptor
  ALLOWED_DOMAINS = ENV.fetch('STAGING_MAIL_ALLOWED_DOMAINS', 'gfsc.studio,placecal.org')
                       .split(',').map(&:strip).freeze
  FALLBACK = ENV.fetch('STAGING_MAIL_FALLBACK', 'support@placecal.org')

  def self.delivering_email(message)
    original = Array(message.to)
    safe = original.select { |address| allowed?(address) }
    return if safe == original

    message.header['X-Original-To'] = original.join(', ')
    message.to = safe.presence || [FALLBACK]
    message.cc = Array(message.cc).select { |address| allowed?(address) }.presence
    message.bcc = Array(message.bcc).select { |address| allowed?(address) }.presence
  end

  def self.allowed?(address)
    ALLOWED_DOMAINS.any? { |domain| address.to_s.downcase.end_with?("@#{domain.downcase}") }
  end
end

ActionMailer::Base.register_interceptor(StagingMailInterceptor) if Rails.env.staging? # rubocop:disable Rails/UnknownEnv
