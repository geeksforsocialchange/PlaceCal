# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Calendar, type: :model do
  describe 'associations' do
    # NOTE: partner has optional: true on association but presence validation
    it { is_expected.to belong_to(:partner).optional(false) }

    # NOTE: place is conditionally required based on strategy (default strategy is 'place')
    # Test with a strategy that doesn't require place
    it 'belongs to place (optional based on strategy)' do
      calendar = described_class.new(strategy: 'event')
      expect(calendar).to belong_to(:place).class_name('Partner').optional
    end

    it { is_expected.to have_many(:events).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:partner) }
    it { is_expected.to validate_presence_of(:source) }

    describe 'source URL validation' do
      let(:partner) { create(:partner) }

      it 'accepts valid https URLs' do
        calendar = build(:calendar, partner: partner, source: 'https://example.com/calendar.ics')
        # Skip the reachability check for testing
        allow(calendar).to receive(:check_source_reachable)
        expect(calendar).to be_valid
      end

      it 'accepts webcal URLs' do
        calendar = build(:calendar, partner: partner, source: 'webcal://example.com/calendar.ics')
        allow(calendar).to receive(:check_source_reachable)
        expect(calendar).to be_valid
      end

      it 'rejects invalid URLs' do
        calendar = build(:calendar, partner: partner, source: 'not-a-url')
        allow(calendar).to receive(:check_source_reachable)
        expect(calendar).not_to be_valid
        expect(calendar.errors[:source]).to include('not a valid URL')
      end
    end

    describe 'place requirement' do
      let(:partner) { create(:partner) }

      %i[place room_number event_override].each do |strategy|
        it "requires place for #{strategy} strategy" do
          # Build with 'event' strategy first (doesn't require place), then change
          calendar = build(:calendar, partner: partner, strategy: 'event')
          calendar.place = nil
          calendar.strategy = strategy
          allow(calendar).to receive(:check_source_reachable)
          expect(calendar).not_to be_valid
          expect(calendar.errors[:place]).to include("can't be blank with this strategy")
        end
      end

      %i[event no_location online_only].each do |strategy|
        it "does not require place for #{strategy} strategy" do
          calendar = build(:calendar, partner: partner, strategy: strategy, place: nil)
          allow(calendar).to receive(:check_source_reachable)
          calendar.valid?
          expect(calendar.errors[:place]).to be_empty
        end
      end
    end
  end

  describe 'enumerizations' do
    describe 'strategy' do
      it 'defaults to place' do
        calendar = described_class.new
        expect(calendar.strategy).to eq('place')
      end

      it 'allows valid strategies' do
        %i[event_override event place room_number no_location online_only].each do |strategy|
          calendar = build(:calendar, strategy: strategy)
          expect(calendar.strategy.to_sym).to eq(strategy)
        end
      end
    end

    describe 'calendar_state' do
      it 'defaults to idle' do
        calendar = described_class.new
        expect(calendar.calendar_state).to eq('idle')
      end

      it 'allows valid states' do
        %i[idle in_queue in_worker error bad_source].each do |state|
          calendar = build(:calendar, calendar_state: state)
          expect(calendar.calendar_state.to_sym).to eq(state)
        end
      end
    end
  end

  describe 'factories' do
    it 'creates a valid ics calendar' do
      calendar = build(:ics_calendar)
      allow(calendar).to receive(:check_source_reachable)
      expect(calendar).to be_valid
    end

    it 'creates a valid eventbrite calendar' do
      calendar = build(:eventbrite_calendar)
      allow(calendar).to receive(:check_source_reachable)
      expect(calendar).to be_valid
    end
  end

  describe '#requires_default_location?' do
    it 'returns true for place strategy' do
      calendar = build(:calendar, strategy: :place)
      expect(calendar.requires_default_location?).to be true
    end

    it 'returns true for room_number strategy' do
      calendar = build(:calendar, strategy: :room_number)
      expect(calendar.requires_default_location?).to be true
    end

    it 'returns true for event_override strategy' do
      calendar = build(:calendar, strategy: :event_override)
      expect(calendar.requires_default_location?).to be true
    end

    it 'returns false for event strategy' do
      calendar = build(:calendar, strategy: :event)
      expect(calendar.requires_default_location?).to be false
    end

    it 'returns false for no_location strategy' do
      calendar = build(:calendar, strategy: :no_location)
      expect(calendar.requires_default_location?).to be false
    end

    it 'returns false for online_only strategy' do
      calendar = build(:calendar, strategy: :online_only)
      expect(calendar.requires_default_location?).to be false
    end
  end

  describe '#events_this_week' do
    let(:calendar) { create(:calendar) }

    before do
      allow(calendar).to receive(:check_source_reachable)
    end

    it 'returns count of events this week' do
      # This is a basic test - actual event counting would need events created
      expect(calendar.events_this_week).to eq(0)
    end
  end
end
