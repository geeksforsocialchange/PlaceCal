# frozen_string_literal: true

require "rails_helper"

# Regression coverage for issue #2358: a user-entered custom slug must survive a
# validation-failure round-trip so the re-rendered form shows what was typed,
# instead of FriendlyId silently reverting it to the previous slug.
RSpec.describe SlugRetainable do
  shared_examples "retains a user-entered slug on validation failure" do
    it "keeps the submitted slug when only the slug is invalid (duplicate)" do
      create(factory, name: "Already Taken Name", slug: "taken-slug")
      record = create(factory, name: "Some Existing Name")

      saved = record.update(slug: "taken-slug")

      expect(saved).to be(false)
      expect(record.errors[:slug]).to be_present
      expect(record.slug).to eq("taken-slug")
    end

    it "keeps the submitted slug when another field is also invalid" do
      create(factory, name: "Already Taken Name", slug: "taken-slug")
      record = create(factory, name: "Some Existing Name")

      record.update(slug: "taken-slug", name: invalid_name)

      expect(record.slug).to eq("taken-slug")
    end

    it "persists a valid custom slug as before" do
      record = create(factory, name: "Some Existing Name")

      expect(record.update(slug: "fresh-custom-slug")).to be(true)
      expect(record.reload.slug).to eq("fresh-custom-slug")
    end
  end

  describe "Partner" do
    let(:factory) { :partner }
    # too short to satisfy the name length validation
    let(:invalid_name) { "x" }

    include_examples "retains a user-entered slug on validation failure"

    it "still auto-generates a slug from the name when none is given" do
      # guards against the override accidentally disabling slug generation
      partner = create(:partner, name: "Brand New Thing")

      expect(partner.slug).to eq("brand-new-thing")
    end
  end

  describe "Site" do
    let(:factory) { :site }
    let(:invalid_name) { "" }

    include_examples "retains a user-entered slug on validation failure"
  end

  describe "Tag" do
    let(:factory) { :tag }
    let(:invalid_name) { "" }

    include_examples "retains a user-entered slug on validation failure"
  end
end
