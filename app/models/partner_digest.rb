# frozen_string_literal: true

# Assembles the content of one user's partner digest email (#3256 phase 2):
# one section per administered partner, each in exactly one of three states
# — healthy feed, failing feed, or no calendar connected. A plain data
# object so mailer previews can construct variants without touching the DB.
class PartnerDigest
  FAILING_STATES = %w[error bad_source].freeze
  UPCOMING_EVENTS_LIMIT = 5

  Section = Data.define(:partner, :status, :last_import_at, :upcoming_events, :failing_calendars) do
    def healthy? = status == :healthy
    def failing? = status == :failing
    def no_calendar? = status == :no_calendar
  end

  attr_reader :user

  # Shared by the HTML and text views: which i18n reason applies to a
  # failing calendar (critical errors without a failing state read as
  # :error)
  # @param calendar [Calendar]
  # @return [String]
  def self.failing_reason_key(calendar)
    state = calendar.calendar_state.to_s
    FAILING_STATES.include?(state) ? state : 'error'
  end

  # @param user [User]
  # @param sections [Array<Section>, nil] override for previews/tests
  def initialize(user, sections: nil)
    @user = user
    @sections = sections
  end

  # @return [Array<Section>] one per visible partner, ordered by name —
  #   the digest describes what's published, so hidden partners are out
  def sections
    @sections ||= user.partners.visible.includes(:calendars).order(:name)
                      .map { |partner| build_section(partner) }
  end

  # The first digest doubles as reintroduction, transparency notice and
  # re-permissioning moment (see #3256 A5) — it carries an extended intro.
  def first_contact?
    user.partner_digest_last_sent_at.nil?
  end

  private

  def build_section(partner)
    calendars = partner.calendars.to_a
    failing = calendars.select do |calendar|
      FAILING_STATES.include?(calendar.calendar_state.to_s) || calendar.critical_error.present?
    end

    if calendars.empty?
      # Their events (if any) are manually added — don't imply breakage
      Section.new(partner: partner, status: :no_calendar, last_import_at: nil,
                  upcoming_events: upcoming_events_for(partner), failing_calendars: [])
    elsif failing.any?
      Section.new(partner: partner, status: :failing, last_import_at: nil,
                  upcoming_events: [], failing_calendars: failing)
    else
      Section.new(partner: partner, status: :healthy,
                  last_import_at: calendars.filter_map(&:last_import_at).max,
                  upcoming_events: upcoming_events_for(partner), failing_calendars: [])
    end
  end

  def upcoming_events_for(partner)
    partner.events.upcoming.order(:dtstart).limit(UPCOMING_EVENTS_LIMIT).to_a
  end
end
