# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::ResidentAdvisor do
  MAXIMUM_RA_RETURNED_RESULTS = 10

  let(:valid_ra_club) { "https://ra.co/clubs/182584" }
  let(:valid_ra_promoter) { "https://ra.co/promoters/73787" }
  # Don't wrap in VCR here - let each test manage its own cassette
  let(:promoter_calendar) do
    build(
      :calendar,
      strategy: :event,
      name: :import_ra_promoter,
      source: valid_ra_promoter
    )
  end

  describe "#ra_entity" do
    it "detects club urls" do
      VCR.use_cassette(:ra_promoter) do
        parser = described_class.new(promoter_calendar)
        expect(parser.ra_entity("https://ra.co/clubs/182584")).to eq([:clubs, 182_584])
      end
    end

    it "detects promoter urls" do
      VCR.use_cassette(:ra_promoter) do
        parser = described_class.new(promoter_calendar)
        expect(parser.ra_entity("https://ra.co/promoters/133684")).to eq([:promoters, 133_684])
      end
    end

    it "rejects if its not a promoter or club" do
      VCR.use_cassette(:ra_promoter) do
        parser = described_class.new(promoter_calendar)
        expect(parser.ra_entity("https://ra.co/promarters/133684")).to be_falsy
        expect(parser.ra_entity("https://ras.co/clubs/133684")).to be_falsy
        expect(parser.ra_entity("https://ra.co/133684")).to be_falsy
        expect(parser.ra_entity("https://ra.co/asdasd/")).to be_falsy
      end
    end
  end

  describe "#download_calendar" do
    it "promoter links download events" do
      VCR.use_cassette(:ra_promoter) do
        parser = described_class.new(promoter_calendar)
        records = parser.download_calendar
        expect(records).to be_a(Array)
        expect(records.count).to eq(MAXIMUM_RA_RETURNED_RESULTS)
      end
    end

    it "club links download events" do
      VCR.use_cassette(:ra_club) do
        ra_club_calendar = build(
          :calendar,
          strategy: :event,
          name: :import_ra_club,
          source: valid_ra_club
        )
        club_parser = described_class.new(ra_club_calendar)

        records = club_parser.download_calendar
        expect(records).to be_a(Array)
        expect(records.count).to eq(MAXIMUM_RA_RETURNED_RESULTS)
      end
    end
  end
end
