# frozen_string_literal: true

# StrongMigrations guards `rails db:migrate` against operations that can lock
# tables or break a running app (adding a NOT NULL column, removing a column,
# changing a type, adding an index non-concurrently, etc.) and explains the
# safe alternative. See https://github.com/ankane/strong_migrations

# Only check migrations created after this point — every existing migration
# predates the gem and is already deployed, so we don't want to flag history.
# Set to the latest migration version present when the gem was introduced.
StrongMigrations.start_after = 20_260_610_090_000

# Auto-set the lock timeout for migrations so a blocked migration fails fast
# instead of holding a lock and stalling requests.
StrongMigrations.lock_timeout = 10.seconds

# Tailors checks to our PostgreSQL version (uncomment and set to the prod major
# version to enable version-specific safety advice, e.g. safe-by-default
# behaviours added in newer Postgres):
# StrongMigrations.target_version = 16
