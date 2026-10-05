# frozen_string_literal: true

require "rails_helper"

# Who may put a site on which theme (#3368, WP 4.5). An extension theme is not
# a colour scheme: it swaps in an engine's views, components and copy, so only
# root moves a site onto one, or off one. Clearing the theme is that same move
# by another name, which is what most of this file is about.
RSpec.describe SitePolicy, :theme_registry, type: :policy do
  subject(:policy) { described_class.new(user, site) }

  let(:site_admin) { create(:citizen_user) }
  let(:root_user) { create(:root_user) }

  # A second extension theme, so "root may move between extension themes" is a
  # move rather than a no-op. :theme_registry restores the registry afterwards.
  before { PlaceCal::Extensions.register_theme(:another_theme) { |theme| theme.stylesheet "another_theme/theme" } }

  describe "#permitted_theme?" do
    context "as the site admin of an extension-themed site" do
      let(:user) { site_admin }
      let(:site) { create(:site, theme: "example_theme", site_admin: site_admin) }

      it "cannot blank the theme" do
        expect(policy.permitted_theme?("")).to be(false)
      end

      it "cannot blank it with a nil either" do
        expect(policy.permitted_theme?(nil)).to be(false)
      end

      it "cannot move it onto another extension theme" do
        expect(policy.permitted_theme?("another_theme")).to be(false)
      end

      # Core themes stay on offer whatever the site is on now, so this is a
      # move a site admin may make. Blanking is not the same thing: it leaves
      # the site on no theme at all.
      it "may move it onto a core theme" do
        expect(policy.permitted_theme?("blue")).to be(true)
      end

      it "may leave it where it is" do
        expect(policy.permitted_theme?("example_theme")).to be(true)
      end
    end

    context "as the site admin of a core-themed site" do
      let(:user) { site_admin }
      let(:site) { create(:site, theme: "pink", site_admin: site_admin) }

      it "cannot blank the theme" do
        expect(policy.permitted_theme?("")).to be(false)
      end

      it "may move it between core themes" do
        expect(policy.permitted_theme?("blue")).to be(true)
      end

      it "cannot move it onto an extension theme" do
        expect(policy.permitted_theme?("example_theme")).to be(false)
      end
    end

    # Site#theme is validated only on change, so a row left naming nothing
    # stays saveable. The policy has to agree, or that site can never be
    # edited at all.
    context "when the stored theme is already blank" do
      let(:user) { site_admin }
      let(:site) do
        create(:site, theme: "pink", site_admin: site_admin).tap do |record|
          # Deliberately behind the validations: this is the historic row
          # shape, which the app itself can no longer produce.
          record.update_column(:theme, "") # rubocop:disable Rails/SkipsModelValidations
        end
      end

      it "may stay blank" do
        expect(policy.permitted_theme?("")).to be(true)
      end

      it "may still be given a core theme" do
        expect(policy.permitted_theme?("blue")).to be(true)
      end
    end

    context "as root" do
      let(:user) { root_user }
      let(:site) { create(:site, theme: "example_theme") }

      it "may move between extension themes" do
        expect(policy.permitted_theme?("another_theme")).to be(true)
      end

      it "may move to a core theme" do
        expect(policy.permitted_theme?("pink")).to be(true)
      end

      it "may not blank an extension theme either: blank is not a registered theme" do
        expect(policy.permitted_theme?("")).to be(false)
      end
    end
  end

  describe "#permitted_themes" do
    let(:site) { create(:site, theme: "example_theme", site_admin: site_admin) }

    context "as a site admin" do
      let(:user) { site_admin }

      it "offers the core themes plus the one the site is already on" do
        expect(policy.permitted_themes.map(&:name))
          .to contain_exactly("pink", "orange", "green", "blue", "example_theme")
      end
    end

    context "as root" do
      let(:user) { root_user }

      it "offers every registered theme" do
        expect(policy.permitted_themes.map(&:name)).to include("example_theme", "another_theme", "pink")
      end
    end
  end
end
