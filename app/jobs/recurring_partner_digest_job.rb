# frozen_string_literal: true

# Self-rescheduling scheduler for the partner digest (#3256 phase 2). Runs
# daily but the send interval is enforced per-user, not per-run: each pass
# enqueues one staggered PartnerDigestDeliveryJob for every user who is due
# (administers >= 1 partner, still subscribed, last sent more than the
# interval ago). No inline sending.
#
# PAUSE SWITCH: sending is off unless PARTNER_DIGEST_ENABLED=true, so a
# deploy can't trigger the first send before the launch runbook gates in
# doc/adr/0015-email-subscription-and-consent-architecture.md are met.
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

        # The cap makes the daily scheduler self-batching: a backlog (the
        # first send, or a quarter boundary) drains over several days,
        # protecting deliverability per the launch runbook. Anyone not
        # reached today is still due tomorrow.
        due_users.first(self.class.daily_send_cap).each_with_index do |user, index|
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

  # @return [Integer] max digests enqueued per daily run
  def self.daily_send_cap
    ENV.fetch('PARTNER_DIGEST_DAILY_CAP', '50').to_i
  end

  private

  # The subscription check here is queue hygiene (don't enqueue jobs that
  # would be suppressed); EmailListGuard remains the enforcement backstop.
  def due_users
    cutoff = self.class.send_interval.ago

    due = User.joins(:partners)
              .where(partner_digest_last_sent_at: [nil, ..cutoff])
              .distinct

    EmailSubscription.subscribed_users(due, :partner_digest)
  end
end
