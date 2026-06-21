# frozen_string_literal: true

# Local CI — run the whole pipeline with `bin/ci` (Rails 8.1's
# ActiveSupport::ContinuousIntegration). This mirrors the lint / security / test
# jobs in .github/workflows/test-and-deploy.yml so the same checks run locally
# and in the cloud.
#
# The test steps need a prepared test database, built assets, and Chrome (for
# system/cucumber specs) — a normal dev machine has these. While iterating, run
# the individual commands directly; reach for `bin/ci` as the full gate before
# pushing.
CI.run do
  step 'Style: JS/CSS format', 'bin/yarn run format:check'
  step 'Style: Ruby', 'bundle exec rubocop'

  step 'Security: Brakeman', 'bundle exec brakeman --no-pager'
  step 'Security: Importmap audit', 'bin/importmap audit'

  step 'DB: prepare test database', 'env RAILS_ENV=test bin/rails db:test:prepare'
  step 'Assets: JS build', 'bin/yarn run build:all'
  step 'Assets: SCSS build', 'bin/rails dartsass:build'
  step 'Assets: precompile', 'env RAILS_ENV=test bin/rails assets:precompile'

  step 'Tests: RSpec (unit)', "bundle exec rspec --exclude-pattern 'spec/system/**/*'"
  step 'Tests: RSpec (system)', 'env RUN_SLOW_TESTS=true bundle exec rspec spec/system'
  step 'Tests: Cucumber (admin)', 'bundle exec cucumber --tags "not @wip" features/admin'
  step 'Tests: Cucumber (public)',
       'bundle exec cucumber --tags "not @wip" features/public features/authentication.feature'

  step 'DB: consistency', 'env RAILS_ENV=test bundle exec database_consistency'
end
