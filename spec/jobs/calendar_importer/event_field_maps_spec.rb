# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::Base do
  def self.event_classes
    Rails.root.glob("app/jobs/calendar_importer/events/*.rb")
         .map { |path| "CalendarImporter::Events::#{path.basename('.rb').to_s.camelize}".constantize }
         .excluding(described_class)
  end

  it "finds the event classes" do
    expect(self.class.event_classes).to include(CalendarImporter::Events::IcsEvent, CalendarImporter::Events::OutsavvyEvent)
  end

  event_classes.each do |klass|
    describe klass.name do
      it "declares every event field, directly or inherited" do
        expect(klass.field_map&.keys).to match_array(described_class::FIELDS.keys)
      end

      it "has a method below Base for each field it declares as imported" do
        klass.field_map.compact_blank.each_key do |field|
          methods = described_class::FIELDS.fetch(field)
          defined = methods.select { |name| klass.method_defined?(name) && klass.instance_method(name).owner != described_class }
          expect(defined).to be_present, "#{klass.name} declares #{field} imported but none of #{methods.join(', ')} is defined"
        end
      end
    end
  end

  it "has no declaration of its own" do
    expect(described_class.field_map).to be_nil
  end

  it "lets a subclass inherit its parent's declaration and override entries" do
    parent = CalendarImporter::Events::LinkedDataEvent
    child = Class.new(parent) { imports image: nil }

    expect(CalendarImporter::Events::OutsavvyEvent.field_map).to eq(parent.field_map)
    expect(child.field_map).to eq(parent.field_map.merge(image: nil))
    expect(parent.field_map[:image]).to eq("image")
  end

  it "rejects a field that isn't an event field" do
    expect { Class.new(described_class) { imports colour: "colour" } }.to raise_error(ArgumentError, /colour/)
  end

  it "is the parent of every parser's event class" do
    CalendarImporter::CalendarImporter::PARSERS.each do |parser|
      expect(parser.event_class).to be < described_class
    end
  end

  it "is what OutSavvy builds its events from, through its own event class" do
    calendar = build(:calendar, source: "https://www.outsavvy.com/organiser/test")
    parser = CalendarImporter::Parsers::Outsavvy.new(calendar, url: calendar.source)
    data = { "@type" => "http://schema.org/Event", "name" => "Gig", "url" => "https://www.outsavvy.com/event/1/gig",
             "start_date" => { "@value" => 1.year.from_now.iso8601 } }

    expect(parser.import_events_from(data)).to contain_exactly(an_instance_of(CalendarImporter::Events::OutsavvyEvent))
  end
end
