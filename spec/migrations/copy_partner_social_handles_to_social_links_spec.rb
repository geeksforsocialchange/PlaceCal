# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261119100100_copy_partner_social_handles_to_social_links.rb")

RSpec.describe CopyPartnerSocialHandlesToSocialLinks do
  subject(:migration) { described_class.new }

  let(:old_partner) { described_class::MigrationPartner }

  before { ActiveRecord::Migration.verbose = false }

  def partner_with(**old_fields)
    partner = create(:partner)
    old_partner.where(id: partner.id).update_all(old_fields.merge(social_links: [])) # rubocop:disable Rails/SkipsModelValidations
    partner
  end

  it "turns the old Facebook, Instagram and X fields into links, in that order" do
    partner = partner_with(facebook_link: "HulmeCommunity", instagram_handle: "hulmecc", twitter_handle: "@hulme_cc")

    migration.up

    expect(partner.reload.social_links).to eq(
      ["https://www.facebook.com/HulmeCommunity", "https://www.instagram.com/hulmecc/", "https://x.com/hulme_cc"]
    )
  end

  it "skips blank fields and keeps a value that is already a full address" do
    partner = partner_with(facebook_link: " ", instagram_handle: "https://www.instagram.com/hulmecc/", twitter_handle: nil)

    migration.up

    expect(partner.reload.social_links).to eq(["https://www.instagram.com/hulmecc/"])
  end

  it "leaves a partner with no old fields with an empty list" do
    partner = partner_with(facebook_link: nil, instagram_handle: "", twitter_handle: nil)

    migration.up

    expect(partner.reload.social_links).to eq([])
  end

  it "is safe to run again, leaving links the partner has since edited alone" do
    partner = partner_with(facebook_link: "HulmeCommunity", instagram_handle: nil, twitter_handle: "hulme_cc")
    migration.up
    partner.update!(social_links: ["https://bsky.app/profile/hulmecc.bsky.social"])

    migration.up
    migration.up

    expect(partner.reload.social_links).to eq(["https://bsky.app/profile/hulmecc.bsky.social"])
  end

  it "stores a JSON array" do
    partner = partner_with(facebook_link: "HulmeCommunity")

    migration.up

    expect(old_partner.where(id: partner.id).pick(Arel.sql("jsonb_typeof(social_links)"))).to eq("array")
  end
end
