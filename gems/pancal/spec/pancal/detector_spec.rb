# frozen_string_literal: true

# Ported from PlaceCal spec/jobs/calendar_importer/calendar_importer_spec.rb
# (CalendarImporter::CalendarImporter -> PanCal.detect / PanCal::Detector).

RSpec.describe PanCal::Detector do
  describe 'reader detection' do
    context 'with webcal calendars' do
      let(:url) { 'webcal://p24-calendars.icloud.com/published/2/WvhkIr4F3oBQrToPU-lkO6WwDTpzNTpENs-Qtbo48FhhrAfDp3gkIal2XPd5eUVO0LLERrehetRzj43c6zvbotf9_DNI6heKXBejvAkz8JQ' }

      it 'imports webcal calendars' do
        VCR.use_cassette('Yellowbird_Webcal', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(2)
          expect(events.first.summary).to eq('Age Friendly Community Soup')
          expect(events.last.summary).to eq('YellowBird Age Friendly Drop-in')
        end
      end
    end

    context 'with google calendars' do
      let(:url) { 'https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics' }

      it 'imports google calendars' do
        VCR.use_cassette('Placecal_Hulme_Moss_Side_Google_Cal', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(139)
          expect(events.first.summary).to eq('Dementia Friends Walk and Talk Group')
          expect(events.first.description).to eq('Session run by Together Dementia Support call Sally on: 0161 2839970')
        end
      end
    end

    context 'with outlook365.com calendars' do
      let(:url) { 'https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics' }

      it 'imports outlook365.com calendars' do
        VCR.use_cassette('Zion_Centre_Guide', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(24)
          expect(events.first.summary).to eq('Hypnotherapy')
          expect(events.last.summary).to eq('Donna - Ashtanga Yoga')
        end
      end
    end

    context 'with live.com calendars' do
      let(:url) { 'https://outlook.live.com/owa/calendar/1c816fe0-358f-4712-9b0f-0265edacde57/8306ff62-3b76-4ad5-8dbe-db435bfea444/cid-536CE5C17F8CF3C2/calendar.ics' }

      it 'imports live.com calendars' do
        VCR.use_cassette('ACCG', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(0)
        end
      end
    end

    context 'with manchester uni calendars' do
      let(:url) { 'http://events.manchester.ac.uk/f3vf/calendar/tag:martin_harris_centre/view:list/p:q_details/calml.xml' }

      it 'imports manchester uni calendars' do
        VCR.use_cassette('Martin_Harris_Centre', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(3)
          expect(events.first.summary).to eq('Technical tours of the Martin Harris Centre for Music and Drama')
          expect(events.last.summary).to eq('KIDNAP@20: The Art of Incarceration')
        end
      end
    end

    context 'with ticketsolve calendars' do
      let(:url) { 'https://z-arts.ticketsolve.com/shows.xml' }

      it 'imports ticketsolve calendars' do
        VCR.use_cassette('Z-Arts_Calendar', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(38)
          expect(events.first.summary).to eq('Inuk')
          expect(events.last.summary).to eq('ZYP: Unusual Theatre in Unusual Spaces')
        end
      end
    end

    context 'with teamup calendars' do
      let(:url) { 'https://ics.teamup.com/feed/ksq8ayp7mw5mhb193x/5941140.ics' }

      it 'imports teamup calendars' do
        VCR.use_cassette('Teamup_com_calendar', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(25)
          expect(events.first.summary).to eq('Mudeford Lifeboat Fun Day')
          expect(events.last.summary).to eq('BEETLE DRIVE')
        end
      end
    end

    context 'with eventbrite calendars' do
      let(:url) { 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483' }

      it 'imports eventbrite calendars' do
        VCR.use_cassette('Eventbrite_calendar', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(73)
          expect(events.first.summary).to eq('Do You Believe in Life After Loss – Andrew Flewitt in Conversation.')
          expect(events.last.summary).to eq('Write That Novel: A writers workshop')
        end
      end
    end

    context 'with squarespace calendars' do
      let(:url) { 'https://robin-cunningham-dh7d.squarespace.com/our-events/' }

      it 'imports squarespace calendars' do
        VCR.use_cassette('Squarespace_calendar', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(16)
          expect(events.first.summary).to eq('crazinsT artisT: Before Dawn')
          expect(events.last.summary).to eq('The Matrix: Dance Dance Revolutions')
        end
      end
    end

    context 'with DiceFM (ld+json) calendars' do
      let(:url) { 'https://dice.fm/venue/folklore-2or7' }

      it 'imports DiceFM events from ld+json source' do
        VCR.use_cassette('dice_fm_events', allow_playback_repeats: true) do
          source = PanCal::Source.new(url: url)

          reader_class = PanCal.detect(source)
          result = reader_class.new(source).read
          events = result.events

          expect(events.count).to eq(15)
          expect(events.first.summary).to eq('Kai Bosch')
          expect(events.last.summary).to eq('Molly Payton')
        end
      end
    end

    context 'with ticketsource calendars' do
      let(:url) { 'https://www.ticketsource.co.uk/fairfield-house' }

      let(:events_response) do
        {
          'data' => [
            {
              'id' => 'evt_1',
              'type' => 'event',
              'attributes' => {
                'name' => 'Guided Tour',
                'description' => 'A guided tour',
                'reference' => 'guided-tour',
                'archived' => false,
                'public' => true
              }
            }
          ],
          'links' => { 'next' => nil }
        }.to_json
      end

      let(:dates_response) do
        {
          'data' => [
            {
              'id' => 'date_1',
              'attributes' => {
                'start' => '2026-03-15T10:00:00+00:00',
                'end' => '2026-03-15T12:00:00+00:00',
                'cancelled' => false
              }
            }
          ]
        }.to_json
      end

      let(:venues_response) do
        {
          'data' => [
            {
              'id' => 'ven_1',
              'attributes' => {
                'name' => 'Fairfield House',
                'address' => { 'line_1' => 'Bath', 'postcode' => 'BA1 5AH' }
              }
            }
          ]
        }.to_json
      end

      it 'imports ticketsource calendars' do
        stub_request(:get, %r{api\.ticketsource\.io/events\?})
          .to_return(status: 200, body: events_response, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{api\.ticketsource\.io/events/evt_1/dates})
          .to_return(status: 200, body: dates_response, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{api\.ticketsource\.io/events/evt_1/venues})
          .to_return(status: 200, body: venues_response, headers: { 'Content-Type' => 'application/json' })

        source = PanCal::Source.new(url: url, reader: 'ticketsource', token: 'test_key')

        reader_class = PanCal.detect(source)
        result = reader_class.new(source).read
        events = result.events

        expect(events.count).to eq(1)
        expect(events.first.summary).to eq('Guided Tour')
      end
    end
  end

  describe 'checksum handling' do
    let(:url) { 'https://z-arts.ticketsolve.com/shows.xml' }
    let(:checksum) { 'd1a94a9869af91d0548a1faf0ded91d7' }

    it 'does not import if checksum is the same' do
      VCR.use_cassette('Z-Arts_Calendar', allow_playback_repeats: true) do
        source = PanCal::Source.new(url: url, last_checksum: checksum)

        reader_class = PanCal.detect(source)
        result = reader_class.new(source).read

        expect(result.events).to be_empty
        expect(result).not_to be_changed
      end
    end
  end

  describe 'auto detection' do
    it 'can pick up ld+json source' do
      VCR.use_cassette('heart_of_torbay') do
        source = PanCal::Source.new(url: 'https://www.heartoftorbaycic.com/events', reader: 'auto')

        reader_class = PanCal.detect(source)
        expect(reader_class::KEY).to eq('ld-json')
      end
    end

    it 'raises error for unhandled calendar sources' do
      VCR.use_cassette('gfsc_studio') do
        source = PanCal::Source.new(url: 'https://gfsc.studio', reader: 'auto')

        expect do
          PanCal.detect(source)
        end.to raise_error(PanCal::UnsupportedFeed)
      end
    end
  end

  describe 'bad URL handling' do
    it 'raises error for empty URL' do
      source = PanCal::Source.new(url: '')

      expect do
        PanCal.detect(source)
      end.to raise_error(PanCal::UnsupportedFeed, /missing/)
    end

    it 'raises error for invalid URL format' do
      source = PanCal::Source.new(url: 'hts://example,com')

      expect do
        PanCal.detect(source)
      end.to raise_error(PanCal::UnsupportedFeed, /not a valid URL/)
    end
  end

  describe 'requires_api_token?' do
    it 'skips HTTP reachability check for Ticket Tailor URLs' do
      source = PanCal::Source.new(url: 'https://www.tickettailor.com/events/testorg')

      # This should not make any HTTP requests - if it did, WebMock would raise
      expect(PanCal.detect(source)).to eq(PanCal::Readers::Tickettailor)
    end

    it 'skips HTTP reachability check for TicketSource URLs' do
      source = PanCal::Source.new(url: 'https://www.ticketsource.co.uk/some-venue')

      expect(PanCal.detect(source)).to eq(PanCal::Readers::Ticketsource)
    end

    it 'still performs HTTP reachability check for other URLs' do
      VCR.use_cassette(:example_dot_com_bad_response, allow_playback_repeats: true) do
        source = PanCal::Source.new(url: 'https://example.com/')

        expect do
          PanCal.detect(source)
        end.to raise_error(PanCal::InaccessibleFeed)
      end
    end
  end
end
