# frozen_string_literal: true

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Configure 'rails notes' to inspect Cucumber files
  config.annotations.register_directories('features')
  config.annotations.register_extensions('feature') { |tag| /#\s*(#{tag}):?\s*(.*)$/ }

  routes.default_url_options = {
    host: ENV.fetch('SITE_DOMAIN', 'lvh.me'),
    port: 3000,
    protocol: 'http'
  }

  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = routes.default_url_options

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # https://stackoverflow.com/questions/78862599/argumenterror-assert-no-enqueued-jobs-requires-the-active-job-test-adapter-you
  config.active_job.queue_adapter = :test

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  config.assets.paths << Rails.root.join('app/javascript')

  # Disable CSS/JS compression in test to avoid SassC compressor issues with asset paths
  config.assets.css_compressor = nil
  config.assets.js_compressor = nil
end
