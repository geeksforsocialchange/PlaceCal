# frozen_string_literal: true

# Shared mock data for Lookbook previews.
# Uses Structs to satisfy Literal::Properties type checks
# without requiring database records.
module PreviewSupport
  AddressMock = Struct.new(:street_address, :postcode, :neighbourhood) do
    def all_address_lines
      [street_address, postcode].compact
    end
  end

  EventMock = Struct.new(
    :id, :dtstart, :dtend, :summary, :description,
    :partner_at_location, :address, :rrule, :neighbourhood,
    :online_address
  )

  RetinaMock = Struct.new(:url)
  AvatarMock = Struct.new(:retina)
  UserMock = Struct.new(:full_name, :email, :phone, :avatar)

  module_function

  def sample_address(overrides = {})
    AddressMock.new({
      street_address: "42 Oak Lane, Hulme",
      postcode: "M15 5AA",
      neighbourhood: nil
    }.merge(overrides))
  end

  def sample_event(overrides = {})
    EventMock.new({
      id: 1,
      dtstart: Time.zone.parse("2025-06-15 10:00"),
      dtend: Time.zone.parse("2025-06-15 12:00"),
      summary: "Community Coffee Morning",
      description: "A friendly weekly coffee morning for everyone in the neighbourhood.",
      partner_at_location: nil,
      address: sample_address,
      rrule: nil,
      neighbourhood: nil,
      online_address: nil
    }.merge(overrides))
  end

  def sample_online_event
    sample_event(
      id: 2,
      summary: "Online Craft Workshop",
      description: "Join us for an online craft session via Zoom.",
      online_address: "https://zoom.us/meeting/123",
      address: nil
    )
  end

  def sample_repeating_event
    sample_event(
      id: 3,
      summary: "Weekly Walking Group",
      description: "A gentle walk around the local park, every week.",
      rrule: [{ "table" => { "frequency" => "weekly" } }]
    )
  end

  def sample_all_day_event
    sample_event(
      id: 4,
      dtstart: Time.zone.parse("2025-06-20 00:00"),
      dtend: Time.zone.parse("2025-06-20 23:59"),
      summary: "Summer Fair",
      description: "An all-day summer fair with stalls, music, and food."
    )
  end

  def sample_user
    UserMock.new(
      full_name: "Sarah Johnson",
      email: "sarah@placecal.org",
      phone: "0161 234 5678",
      avatar: AvatarMock.new(retina: RetinaMock.new(url: nil))
    )
  end

  def sample_user_minimal
    UserMock.new(
      full_name: "Alex Chen",
      email: "alex@placecal.org",
      phone: nil,
      avatar: AvatarMock.new(retina: RetinaMock.new(url: nil))
    )
  end

  def sample_events_by_day
    today = Time.zone.today
    {
      today => [
        sample_event(dtstart: today.to_time.change(hour: 10), dtend: today.to_time.change(hour: 12)),
        sample_event(id: 5, summary: "Lunch Club", dtstart: today.to_time.change(hour: 12, min: 30), dtend: today.to_time.change(hour: 14))
      ],
      today + 1.day => [
        sample_event(id: 6, summary: "Yoga Class", dtstart: (today + 1.day).to_time.change(hour: 9), dtend: (today + 1.day).to_time.change(hour: 10))
      ]
    }
  end

  def sample_navigation
    [
      ["Events", "/events"],
      ["Partners", "/partners"]
    ]
  end
end
