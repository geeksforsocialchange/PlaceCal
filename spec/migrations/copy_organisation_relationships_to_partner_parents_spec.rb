# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261022150200_copy_organisation_relationships_to_partner_parents.rb")

RSpec.describe CopyOrganisationRelationshipsToPartnerParents do
  subject(:migration) { described_class.new }

  let(:university) { create(:partner) }
  let(:museum) { create(:partner) }
  let(:gallery) { create(:partner) }

  def relate(subject_partner, object_partner)
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      INSERT INTO organisation_relationships (partner_subject_id, verb, partner_object_id)
      VALUES (#{subject_partner.id}, 'manages', #{object_partner.id})
    SQL
  end

  before do
    ActiveRecord::Migration.verbose = false
    relate(university, museum)
    relate(university, gallery)
  end

  describe "#up" do
    it "makes each managing partner the parent of the partners it manages" do
      migration.up

      expect(museum.reload.parent_id).to eq(university.id)
      expect(gallery.reload.parent_id).to eq(university.id)
      expect(university.reload.parent_id).to be_nil
    end

    it "can run twice" do
      2.times { migration.up }

      expect(museum.reload.parent_id).to eq(university.id)
    end
  end

  describe "#down" do
    it "clears the parents" do
      migration.up
      migration.down

      expect(museum.reload.parent_id).to be_nil
    end
  end
end
