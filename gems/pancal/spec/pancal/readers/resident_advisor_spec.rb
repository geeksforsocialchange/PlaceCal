# frozen_string_literal: true

# Ported from PlaceCal spec/jobs/calendar_importer/resident_advisor_parser_spec.rb.

RSpec.describe PanCal::Readers::ResidentAdvisor do
  let(:maximum_ra_returned_results) { 10 }
  let(:valid_ra_club) { 'https://ra.co/clubs/182584' }
  let(:valid_ra_promoter) { 'https://ra.co/promoters/73787' }
  # Don't wrap in VCR here - let each test manage its own cassette
  let(:promoter_source) { PanCal::Source.new(url: valid_ra_promoter) }

  describe '#ra_entity' do
    it 'detects club urls' do
      VCR.use_cassette(:ra_promoter) do
        reader = described_class.new(promoter_source)
        expect(reader.ra_entity('https://ra.co/clubs/182584')).to eq([:clubs, 182_584])
      end
    end

    it 'detects promoter urls' do
      VCR.use_cassette(:ra_promoter) do
        reader = described_class.new(promoter_source)
        expect(reader.ra_entity('https://ra.co/promoters/133684')).to eq([:promoters, 133_684])
      end
    end

    it 'rejects if its not a promoter or club' do
      VCR.use_cassette(:ra_promoter) do
        reader = described_class.new(promoter_source)
        expect(reader.ra_entity('https://ra.co/promarters/133684')).to be_falsy
        expect(reader.ra_entity('https://ras.co/clubs/133684')).to be_falsy
        expect(reader.ra_entity('https://ra.co/133684')).to be_falsy
        expect(reader.ra_entity('https://ra.co/asdasd/')).to be_falsy
      end
    end
  end

  describe '#download_calendar' do
    it 'promoter links download events' do
      VCR.use_cassette(:ra_promoter) do
        reader = described_class.new(promoter_source)
        records = reader.download_calendar
        expect(records).to be_a(Array)
        expect(records.count).to eq(maximum_ra_returned_results)
      end
    end

    it 'club links download events' do
      VCR.use_cassette(:ra_club) do
        ra_club_source = PanCal::Source.new(url: valid_ra_club)
        club_reader = described_class.new(ra_club_source)

        records = club_reader.download_calendar
        expect(records).to be_a(Array)
        expect(records.count).to eq(maximum_ra_returned_results)
      end
    end
  end
end
