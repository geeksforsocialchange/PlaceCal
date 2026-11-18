# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261117140000_treat_empty_values_as_equal_in_events_unique_index.rb")

RSpec.describe TreatEmptyValuesAsEqualInEventsUniqueIndex do
  subject(:migration) { described_class.new }

  before do
    ActiveRecord::Migration.verbose = false
    # Rolled back with the example, so later examples get the index back
    ActiveRecord::Base.connection.remove_index(:events, name: described_class::NAME)
  end

  def copy_of(event, **changes)
    Event.new(event.attributes.except("id", "created_at", "updated_at").merge(changes.stringify_keys)).tap { it.save!(validate: false) }
  end

  it "destroys every duplicate but the oldest, treating empty end times as equal, before the index is built" do
    original = create(:event, dtend: nil)
    duplicates = [copy_of(original), copy_of(original)]
    other_time = copy_of(original, dtstart: original.dtstart + 1.day)

    migration.destroy_duplicates

    expect(Event.where(id: [original, *duplicates, other_time])).to contain_exactly(original, other_time)
  end

  it "destroys nothing when there are no duplicates" do
    events = create_list(:event, 2, calendar: create(:calendar), dtend: nil)

    expect { migration.destroy_duplicates }.not_to change(Event, :count)
    expect(Event.where(id: events)).to match_array(events)
  end
end
