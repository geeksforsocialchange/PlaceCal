# frozen_string_literal: true

require 'test_helper'

class ResidentAdvisorParserTest < ActiveSupport::TestCase
  MAXIMUM_RA_RETURNED_RESULTS = 10

  setup do
    @valid_ra_club = 'https://ra.co/clubs/182584'
    @valid_ra_promoter = 'https://ra.co/promoters/73787'

    VCR.use_cassette(:ra_promoter) do
      ra_promoter_calendar = build(
        :calendar,
        strategy: :event,
        name: :import_ra_promoter,
        source: @valid_ra_promoter
      )
      @promoter_parser = CalendarImporter::Parsers::ResidentAdvisor.new(ra_promoter_calendar)
    end
  end

  # NOTE: this is just testing the method, doesn't matter which parser it uses
  # A bit ugly to use VCR for these, but the calendar importer checks the URL when it instantiates
  test 'detect club urls' do
    VCR.use_cassette(:ra_promoter) do
      assert_equal [:clubs,  182_584], @promoter_parser.ra_entity('https://ra.co/clubs/182584')
    end
  end

  test 'detect promoter urls' do
    VCR.use_cassette(:ra_promoter) do
      assert_equal [:promoters,  133_684], @promoter_parser.ra_entity('https://ra.co/promoters/133684')
    end
  end

  test 'reject if its not a promoter or club' do
    VCR.use_cassette(:ra_promoter) do
      assert_not @promoter_parser.ra_entity('https://ra.co/promarters/133684')
      assert_not @promoter_parser.ra_entity('https://ras.co/clubs/133684')
      assert_not @promoter_parser.ra_entity('https://ra.co/133684')
      assert_not @promoter_parser.ra_entity('https://ra.co/asdasd/')
    end
  end

  test 'promoter links download events' do
    VCR.use_cassette(:ra_promoter) do
      records = @promoter_parser.download_calendar
      assert_kind_of(Array, records)
      assert_equal MAXIMUM_RA_RETURNED_RESULTS, records.count
    end
  end

  test 'club links download events' do
    VCR.use_cassette(:ra_club) do
      ra_club_calendar = build(
        :calendar,
        strategy: :event,
        name: :import_ra_club,
        source: @valid_ra_club
      )
      club_parser = CalendarImporter::Parsers::ResidentAdvisor.new(ra_club_calendar)

      records = club_parser.download_calendar
      assert_kind_of(Array, records)
      assert_equal MAXIMUM_RA_RETURNED_RESULTS, records.count
    end
  end
end
