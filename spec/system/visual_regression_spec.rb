# frozen_string_literal: true

require "rails_helper"

# Full-page screenshots of public pages under each theme, diffed by bin/visual-regression.
# Run directly with: VISUAL_REGRESSION=1 bundle exec rspec spec/system/visual_regression_spec.rb
RSpec.describe "Visual regression screenshots", :visual_regression, type: :system do
  include VisualRegression

  # Runs ahead of the Normal Island lets, so ids and Faker output are identical on every run.
  prepend_before do
    DatabaseCleaner.clean_with(:truncation)
    Faker::Config.random = Random.new(42)
  end

  include_context "normal island data"

  let!(:vr_article) do
    create(:article, title: "Millbrook Community Garden Opens").tap do |article|
      create(:article_partner, article:, partner: riverside_hub)
    end
  end

  around do |example|
    original = Capybara.raise_server_errors
    Capybara.raise_server_errors = false
    example.run
  ensure
    Capybara.raise_server_errors = original
  end

  after { Faker::Config.random = nil }

  VisualRegression::BROWSERS.each do |browser|
    context "in #{browser}" do
      before do
        driven_by :"playwright_#{browser}"
        prepare_browser
      end

      VisualRegression.themes.each do |theme|
        it "captures #{theme.name} site pages" do
          millbrook_site.update!(theme: theme.name)
          theme_pages = theme.pages.keys.to_h { |slug| ["page_#{slug}", -> { "/#{slug}" }] }

          capture_pages(browser, theme.name, VisualRegression::SITE_PAGES.merge(theme_pages), subdomain: millbrook_site.slug)
        end
      end

      it "captures directory and join pages" do
        capture_pages(browser, "core", VisualRegression::APEX_PAGES)
      end
    end
  end
end
