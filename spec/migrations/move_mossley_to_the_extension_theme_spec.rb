# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20260905120000_move_mossley_to_the_extension_theme.rb")

# The one row that moves off core's legacy `custom` theme onto the Mossley
# extension (#3368 WP 5.1). Raw SQL both ways, so nothing here goes through the
# model's validations, which is deliberate: `theme` is validated against the
# extension registry and a migration should not have to satisfy that.
RSpec.describe MoveMossleyToTheExtensionTheme do
  subject(:migration) { described_class.new }

  # Straight to the column, because these are exactly the values the model
  # refuses.
  def site_on(slug, theme)
    create(:site, slug: slug).tap { |site| site.update_column(:theme, theme) } # rubocop:disable Rails/SkipsModelValidations
  end

  before { ActiveRecord::Migration.verbose = false }

  describe "#up" do
    it "moves a site on the legacy custom theme onto the extension" do
      mossley = site_on("mossley", "custom")

      migration.up

      expect(mossley.reload.theme).to eq("mossley")
    end

    it "leaves every other theme alone" do
      pink = site_on("elsewhere", "pink")

      migration.up

      expect(pink.reload.theme).to eq("pink")
    end
  end

  describe "#down" do
    it "puts the Mossley row back" do
      mossley = site_on("mossley", "mossley")

      migration.down

      expect(mossley.reload.theme).to eq("custom")
    end

    # Root can put any site on the mossley theme from the admin select once up
    # has run. Rolling back must not sweep those onto `custom`, which nothing
    # registers any more: they would render unstyled and could not be changed
    # to another unregistered value.
    it "leaves a site put on the mossley theme afterwards where it is" do
      other = site_on("also-mossley-themed", "mossley")

      migration.down

      expect(other.reload.theme).to eq("mossley")
    end
  end
end
