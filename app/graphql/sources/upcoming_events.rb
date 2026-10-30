# frozen_string_literal: true

module Sources
  # Each partner's soonest upcoming events, at most `limit` per partner, in one query
  class UpcomingEvents < GraphQL::Dataloader::Source
    def initialize(limit)
      super()
      @limit = limit
    end

    def fetch(partner_ids)
      ranked = Event.upcoming.where(organiser_id: partner_ids)
                    .select('events.*, ROW_NUMBER() OVER (PARTITION BY organiser_id ORDER BY dtstart, summary) AS position')
      events = Event.from(ranked, :events).where(position: ..@limit).sort_by_time.group_by(&:organiser_id)
      partner_ids.map { |id| events.fetch(id, []) }
    end
  end
end
