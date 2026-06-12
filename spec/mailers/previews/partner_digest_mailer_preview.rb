# frozen_string_literal: true

# Preview at http://lvh.me:3000/rails/mailers/partner_digest_mailer
#
# Builds everything in memory (with fake ids so URL/token generation works)
# rather than reading or writing the development database.
class PartnerDigestMailerPreview < ActionMailer::Preview
  def standard
    PartnerDigestMailer.digest(user, digest: PartnerDigest.new(user, sections: all_state_sections))
  end

  def first_contact
    first_contact_user = user
    first_contact_user.partner_digest_last_sent_at = nil
    PartnerDigestMailer.digest(first_contact_user,
                               digest: PartnerDigest.new(first_contact_user, sections: all_state_sections))
  end

  private

  def user
    user = User.new(id: 1, first_name: "Jo", last_name: "Bloggs", email: "jo@example.com",
                    partner_digest_last_sent_at: 90.days.ago)
    # signed_id (for the confirm/preferences links) refuses new records;
    # pretend this in-memory user is persisted
    user.define_singleton_method(:new_record?) { false }
    user
  end

  def all_state_sections
    [healthy_section, failing_section, no_calendar_section]
  end

  def healthy_section
    partner = Partner.new(id: 1, name: "Riverside Community Hub")
    events = Array.new(3) do |i|
      Event.new(id: i + 1, summary: "Friendly community event #{i + 1}", dtstart: (i + 1).days.from_now)
    end
    PartnerDigest::Section.new(partner: partner, status: :healthy, last_import_at: 2.days.ago,
                               upcoming_events: events, failing_calendars: [])
  end

  def failing_section
    partner = Partner.new(id: 2, name: "Oldtown Library")
    calendar = Calendar.new(id: 1, name: "Library events", calendar_state: :error,
                            critical_error: "Connection refused")
    PartnerDigest::Section.new(partner: partner, status: :failing, last_import_at: nil,
                               upcoming_events: [], failing_calendars: [calendar])
  end

  def no_calendar_section
    partner = Partner.new(id: 3, name: "Greenfield Youth Centre")
    event = Event.new(id: 99, summary: "Hand-added open day", dtstart: 10.days.from_now)
    PartnerDigest::Section.new(partner: partner, status: :no_calendar, last_import_at: nil,
                               upcoming_events: [event], failing_calendars: [])
  end
end
