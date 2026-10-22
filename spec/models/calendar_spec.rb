# frozen_string_literal: true

# == Schema Information
#
# Table name: calendars
#
#  id                   :bigint           not null, primary key
#  api_token            :string
#  calendar_state       :string           default("idle")
#  checksum_updated_at  :datetime
#  critical_error       :text
#  import_started_at    :datetime
#  importer_mode        :string           default("auto")
#  importer_used        :string
#  is_working           :boolean          default(TRUE), not null
#  last_checksum        :string
#  last_import_at       :datetime
#  name                 :string           not null
#  notice_count         :integer
#  notices              :jsonb
#  public_contact_email :string
#  public_contact_name  :string
#  public_contact_phone :string
#  source               :string           not null
#  strategy             :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  import_job_id        :bigint
#  organiser_id         :bigint           not null
#  place_id             :bigint
#
# Indexes
#
#  index_calendars_on_calendar_state  (calendar_state)
#  index_calendars_on_organiser_id    (organiser_id)
#  index_calendars_on_place_id        (place_id)
#  index_calendars_source             (source) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organiser_id => partners.id)
#  fk_rails_...  (place_id => partners.id)
#
require "rails_helper"

RSpec.describe Calendar, type: :model do
  describe "associations" do
    # NOTE: organiser has optional: true on association but presence validation
    it { is_expected.to belong_to(:organiser).class_name("Partner").optional(false) }

    # NOTE: place is conditionally required based on strategy (default strategy is 'place')
    # Test with a strategy that doesn't require place
    it "belongs to place (optional based on strategy)" do
      calendar = described_class.new(strategy: "event")
      expect(calendar).to belong_to(:place).class_name("Partner").optional
    end

    it { is_expected.to have_many(:events).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:organiser) }
    it { is_expected.to validate_presence_of(:source) }

    describe "source URL validation" do
      let(:partner) { create(:partner) }

      it "accepts valid https URLs" do
        calendar = build(:calendar, organiser: partner, source: "https://example.com/calendar.ics")
        # Skip the reachability check for testing
        allow(calendar).to receive(:check_source_reachable)
        expect(calendar).to be_valid
      end

      it "accepts webcal URLs" do
        calendar = build(:calendar, organiser: partner, source: "webcal://example.com/calendar.ics")
        allow(calendar).to receive(:check_source_reachable)
        expect(calendar).to be_valid
      end

      it "rejects a private address before trying to fetch it" do
        calendar = build(:calendar, organiser: partner, source: "http://169.254.169.254/latest/meta-data/")

        expect(calendar.save).to be false
        expect(calendar.errors[:source].join).to include(I18n.t("admin.calendars.wizard.source.private_address"))
        expect(a_request(:any, /.*/)).not_to have_been_made
      end

      it "rejects invalid URLs" do
        calendar = build(:calendar, organiser: partner, source: "not-a-url")
        allow(calendar).to receive(:check_source_reachable)
        expect(calendar).not_to be_valid
        expect(calendar.errors[:source]).to include("not a valid URL")
      end
    end

    describe "place requirement" do
      let(:partner) { create(:partner) }

      %i[place room_number event_override].each do |strategy|
        it "requires place for #{strategy} strategy" do
          # Build with 'event' strategy first (doesn't require place), then change
          calendar = build(:calendar, organiser: partner, strategy: "event")
          calendar.place = nil
          calendar.strategy = strategy
          allow(calendar).to receive(:check_source_reachable)
          expect(calendar).not_to be_valid
          expect(calendar.errors[:place]).to include("can't be blank with this strategy")
        end
      end

      %i[event no_location online_only].each do |strategy|
        it "does not require place for #{strategy} strategy" do
          calendar = build(:calendar, organiser: partner, strategy:, place: nil)
          allow(calendar).to receive(:check_source_reachable)
          calendar.valid?
          expect(calendar.errors[:place]).to be_empty
        end
      end
    end
  end

  describe "enumerizations" do
    describe "strategy" do
      it "defaults to place" do
        calendar = described_class.new
        expect(calendar.strategy).to eq("place")
      end

      it "allows valid strategies" do
        %i[event_override event place room_number no_location online_only].each do |strategy|
          calendar = build(:calendar, strategy:)
          expect(calendar.strategy.to_sym).to eq(strategy)
        end
      end
    end

    describe "calendar_state" do
      it "defaults to idle" do
        calendar = described_class.new
        expect(calendar.calendar_state).to eq("idle")
      end

      it "allows valid states" do
        %i[idle in_queue in_worker error bad_source].each do |state|
          calendar = build(:calendar, calendar_state: state)
          expect(calendar.calendar_state.to_sym).to eq(state)
        end
      end
    end
  end

  describe "factories" do
    it "creates a valid ics calendar" do
      calendar = build(:ics_calendar)
      allow(calendar).to receive(:check_source_reachable)
      expect(calendar).to be_valid
    end

    it "creates a valid eventbrite calendar" do
      calendar = build(:eventbrite_calendar)
      allow(calendar).to receive(:check_source_reachable)
      expect(calendar).to be_valid
    end
  end

  describe "#requires_default_location?" do
    it "returns true for place strategy" do
      calendar = build(:calendar, strategy: :place)
      expect(calendar.requires_default_location?).to be true
    end

    it "returns true for room_number strategy" do
      calendar = build(:calendar, strategy: :room_number)
      expect(calendar.requires_default_location?).to be true
    end

    it "returns true for event_override strategy" do
      calendar = build(:calendar, strategy: :event_override)
      expect(calendar.requires_default_location?).to be true
    end

    it "returns false for event strategy" do
      calendar = build(:calendar, strategy: :event)
      expect(calendar.requires_default_location?).to be false
    end

    it "returns false for no_location strategy" do
      calendar = build(:calendar, strategy: :no_location)
      expect(calendar.requires_default_location?).to be false
    end

    it "returns false for online_only strategy" do
      calendar = build(:calendar, strategy: :online_only)
      expect(calendar.requires_default_location?).to be false
    end
  end

  describe "#events_this_week" do
    let(:calendar) { create(:calendar) }

    before do
      allow(calendar).to receive(:check_source_reachable)
    end

    it "returns count of events this week" do
      # This is a basic test - actual event counting would need events created
      expect(calendar.events_this_week).to eq(0)
    end
  end

  describe "import attempt timestamps" do
    let(:calendar) { create(:calendar) }

    it "stamps import_started_at when an attempt is queued" do
      calendar.update_columns(calendar_state: "idle", import_started_at: nil) # rubocop:disable Rails/SkipsModelValidations

      expect { calendar.queue_for_import!(false) }
        .to change { calendar.reload.import_started_at }.from(nil)

      expect(calendar.calendar_state).to eq("in_queue")
      expect(calendar.import_started_at).to be_within(5.seconds).of(Time.current)
    end

    it "stamps import_started_at when the worker starts the import" do
      calendar.update_columns(calendar_state: "in_queue", import_started_at: nil) # rubocop:disable Rails/SkipsModelValidations

      expect { calendar.flag_start_import_job! }
        .to change { calendar.reload.import_started_at }.from(nil)

      expect(calendar.calendar_state).to eq("in_worker")
      expect(calendar.import_started_at).to be_within(5.seconds).of(Time.current)
    end
  end

  describe "import job tracking" do
    let(:calendar) { create(:calendar) }

    around do |example|
      original = CalendarImporterJob.queue_adapter
      CalendarImporterJob.queue_adapter = :delayed_job
      example.run
    ensure
      CalendarImporterJob.queue_adapter = original
    end

    it "records the delayed job driving the attempt" do
      calendar.update_columns(calendar_state: "idle", import_job_id: 999_999) # rubocop:disable Rails/SkipsModelValidations

      calendar.queue_for_import!(false)

      job = Delayed::Job.last
      expect(job.handler).to include("CalendarImporterJob")
      expect(calendar.reload.import_job_id).to eq(job.id)
    end
  end

  describe ".reset_stuck_imports!" do
    let(:calendar) { create(:calendar) }

    def put_stuck(state, started_at, job_id: nil)
      calendar.update_columns(calendar_state: state, import_started_at: started_at, import_job_id: job_id) # rubocop:disable Rails/SkipsModelValidations
    end

    def delayed_job(**attrs)
      Delayed::Job.create!(handler: "--- {}\n", run_at: Time.current, **attrs)
    end

    context "without a recorded job" do
      %w[in_worker in_queue].each do |state|
        it "resets a calendar stuck in #{state} beyond the threshold" do
          put_stuck(state, 3.hours.ago)

          expect(described_class.reset_stuck_imports!).to contain_exactly(calendar.id)
          expect(calendar.reload.calendar_state).to eq("idle")
        end

        it "resets a legacy #{state} calendar with no import_started_at" do
          put_stuck(state, nil)

          expect(described_class.reset_stuck_imports!).to contain_exactly(calendar.id)
          expect(calendar.reload.calendar_state).to eq("idle")
        end

        it "leaves a #{state} calendar whose attempt started recently" do
          put_stuck(state, 10.minutes.ago)

          expect(described_class.reset_stuck_imports!).to be_empty
          expect(calendar.reload.calendar_state).to eq(state)
        end
      end

      it "honours a custom threshold" do
        put_stuck("in_worker", 30.minutes.ago)

        expect(described_class.reset_stuck_imports!(threshold: 15.minutes)).to contain_exactly(calendar.id)
        expect(calendar.reload.calendar_state).to eq("idle")
      end
    end

    context "with a recorded job" do
      it "leaves an in_queue calendar whose job is waiting in a long backlog" do
        put_stuck("in_queue", 3.hours.ago, job_id: delayed_job.id)

        expect(described_class.reset_stuck_imports!).to be_empty
        expect(calendar.reload.calendar_state).to eq("in_queue")
      end

      it "resets an in_queue calendar whose job no longer exists, without waiting for the threshold" do
        put_stuck("in_queue", 10.minutes.ago, job_id: delayed_job.tap(&:destroy).id)

        expect(described_class.reset_stuck_imports!).to contain_exactly(calendar.id)
        expect(calendar.reload).to have_attributes(calendar_state: "idle", import_job_id: nil)
      end

      it "leaves an in_worker calendar whose job is locked by a worker" do
        put_stuck("in_worker", 3.hours.ago, job_id: delayed_job(locked_at: 1.minute.ago, locked_by: "w1").id)

        expect(described_class.reset_stuck_imports!).to be_empty
        expect(calendar.reload.calendar_state).to eq("in_worker")
      end

      it "leaves an in_worker calendar whose worker died, since Delayed::Job re-runs stale locks" do
        put_stuck("in_worker", 3.hours.ago, job_id: delayed_job(locked_at: 1.day.ago, locked_by: "dead").id)

        expect(described_class.reset_stuck_imports!).to be_empty
        expect(calendar.reload.calendar_state).to eq("in_worker")
      end

      it "leaves a calendar whose job failed and is waiting to retry" do
        job = delayed_job(attempts: 1, run_at: 1.hour.from_now, last_error: "boom")
        put_stuck("in_worker", 3.hours.ago, job_id: job.id)

        expect(described_class.reset_stuck_imports!).to be_empty
        expect(calendar.reload.calendar_state).to eq("in_worker")
      end

      it "resets a calendar whose job exhausted its retries and was kept as failed" do
        put_stuck("in_worker", 10.minutes.ago, job_id: delayed_job(attempts: 4, failed_at: 1.minute.ago).id)

        expect(described_class.reset_stuck_imports!).to contain_exactly(calendar.id)
        expect(calendar.reload.calendar_state).to eq("idle")
      end

      it "leaves a calendar queued within the grace period even if its job is not visible" do
        put_stuck("in_queue", 1.minute.ago, job_id: delayed_job.tap(&:destroy).id)

        expect(described_class.reset_stuck_imports!).to be_empty
        expect(calendar.reload.calendar_state).to eq("in_queue")
      end
    end

    it "ignores calendars that are not in a busy state" do
      put_stuck("bad_source", 3.hours.ago)

      expect(described_class.reset_stuck_imports!).to be_empty
      expect(calendar.reload.calendar_state).to eq("bad_source")
    end
  end
end
