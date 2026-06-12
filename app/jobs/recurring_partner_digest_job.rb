# frozen_string_literal: true

# Self-rescheduling scheduler for the partner digest (#3256 phase 2). Runs
# daily but the send interval is enforced per-user, not per-run: each pass
# enqueues one staggered PartnerDigestDeliveryJob for every user who is due
# (administers >= 1 partner, still subscribed, last sent more than the
# interval ago). No inline sending.
#
# PAUSE SWITCH: sending is off unless PARTNER_DIGEST_ENABLED=true, so a
# deploy can't trigger the first send before the launch gates in
# doc/proposals/3256-partner-email-notifications-prompt.md Part C are met.
# To stop a send in progress: unset the variable and delete queued
# PartnerDigestDeliveryJob rows from delayed_jobs.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringPartnerDigestJob < ApplicationJob
  include SelfRescheduling

  INTERVAL = 1.day
  STAGGER = 30.seconds

  def perform
    run do
      Appsignal::CheckIn.cron('partner_digest') do
        next unless self.class.enabled?

        due_users.each_with_index do |user, index|
          PartnerDigestDeliveryJob.set(wait: index * STAGGER).perform_later(user)
        end
      end
    end
  end

  def self.enabled?
    ENV.fetch('PARTNER_DIGEST_ENABLED', 'false') == 'true'
  end

  # @return [ActiveSupport::Duration] per-user send interval, default quarterly
  def self.send_interval
    ENV.fetch('PARTNER_DIGEST_INTERVAL_DAYS', '90').to_i.days
  end

  private

  # The subscription check here is queue hygiene (don't enqueue jobs that
  # would be suppressed); EmailListGuard remains the enforcement backstop.
  def due_users
    cutoff = self.class.send_interval.ago

    User.joins(:partners)
        .where(partner_digest_last_sent_at: [nil, ..cutoff])
        .distinct
        .select { |user| EmailSubscription.subscribed?(user, :partner_digest) }
  end
end
