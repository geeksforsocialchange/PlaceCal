# frozen_string_literal: true

# Transitional seeding (ADR 0015): every existing partner-admin user gets an
# explicit partner_digest subscription recorded as legacy onboarding, so the
# pre-system verbal-consent era is an honest audit trail rather than implied
# by absence of data. partnership_updates is deliberately NOT seeded — that
# opt-in list starts empty and fills only via affirmative action.
#
# Raw SQL so the migration doesn't depend on model code.
class SeedLegacyEmailSubscriptions < ActiveRecord::Migration[8.1]
  def up
    say_with_time 'seeding partner_digest subscriptions for partner admins' do
      execute(<<~SQL.squish).cmd_tuples
        INSERT INTO email_subscriptions (user_id, list_key, subscribed, source, created_at, updated_at)
        SELECT DISTINCT pu.user_id, 'partner_digest', TRUE, 'legacy_onboarding', NOW(), NOW()
        FROM partners_users pu
        ON CONFLICT (user_id, list_key) DO NOTHING
      SQL
    end

    say_with_time 'recording matching audit events' do
      execute(<<~SQL.squish).cmd_tuples
        INSERT INTO email_subscription_events (user_id, list_key, old_subscribed, new_subscribed, source, created_at)
        SELECT user_id, 'partner_digest', NULL, TRUE, 'legacy_onboarding', NOW()
        FROM email_subscriptions
        WHERE list_key = 'partner_digest' AND source = 'legacy_onboarding'
      SQL
    end
  end

  def down
    execute(<<~SQL.squish)
      DELETE FROM email_subscription_events
      WHERE list_key = 'partner_digest' AND source = 'legacy_onboarding'
    SQL
    execute(<<~SQL.squish)
      DELETE FROM email_subscriptions
      WHERE list_key = 'partner_digest' AND source = 'legacy_onboarding'
    SQL
  end
end
