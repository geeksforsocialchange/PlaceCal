# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventJsonLd do
  let(:schema_path) { Rails.root.join("spec/support/schemas/schema_org_event.json") }
  let(:schema) { JSON.parse(File.read(schema_path)) }
  let(:base_url) { "https://hulme.placecal.org" }

  describe "#to_json_ld" do
    let(:event) { create(:event) }
    let(:data) { event.to_json_ld(base_url: base_url) }

    it "validates against the schema.org Event JSON Schema" do
      errors = JSON::Validator.fully_validate(schema, data)
      expect(errors).to be_empty, -> { "JSON-LD validation errors:\n#{errors.join("\n")}" }
    end

    it "uses base_url for the event URL" do
      expect(data["url"]).to eq("#{base_url}/events/#{event.id}")
    end

    it "formats startDate as ISO 8601" do
      expect(data["startDate"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    context "with endDate" do
      it "includes endDate when dtend is present" do
        expect(data["endDate"]).to be_present
        expect(data["endDate"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end

      it "omits endDate when dtend is nil" do
        event.update!(dtend: nil)
        expect(event.to_json_ld(base_url: base_url)).not_to have_key("endDate")
      end
    end

    context "with description" do
      it "returns plain text with HTML stripped" do
        # description_html is rendered from markdown by HtmlRenderCache
        expect(data["description"]).to be_present
        expect(data["description"]).not_to include("<")
      end

      it "omits description when blank" do
        event.update!(description: "")
        expect(event.reload.to_json_ld(base_url: base_url)).not_to have_key("description")
      end
    end

    context "with physical location" do
      it "includes Place with PostalAddress" do
        location = data["location"]
        expect(location["@type"]).to eq("Place")
        expect(location["address"]["@type"]).to eq("PostalAddress")
        expect(location["address"]["streetAddress"]).to be_present
      end

      it "includes geo coordinates when present" do
        address = event.address
        address.update!(latitude: 53.4808, longitude: -2.2426)
        result = event.reload.to_json_ld(base_url: base_url)
        geo = result["location"]["geo"]
        expect(geo["@type"]).to eq("GeoCoordinates")
        expect(geo["latitude"]).to eq(53.4808)
        expect(geo["longitude"]).to eq(-2.2426)
      end
    end

    context "with online-only location" do
      let(:event) { create(:event, address: nil, online_address: create(:online_address)) }

      it "includes VirtualLocation" do
        location = data["location"]
        expect(location["@type"]).to eq("VirtualLocation")
        expect(location["url"]).to be_present
      end

      it "validates against schema" do
        errors = JSON::Validator.fully_validate(schema, data)
        expect(errors).to be_empty, -> { "JSON-LD validation errors:\n#{errors.join("\n")}" }
      end
    end

    context "without any location" do
      let(:online_only_calendar) { create(:calendar, strategy: "online_only") }
      let(:event) { create(:event, address: nil, online_address: nil, calendar: online_only_calendar) }

      it "omits location key" do
        expect(data).not_to have_key("location")
      end
    end

    context "with organizer" do
      it "includes Organization from partner" do
        organizer = data["organizer"]
        expect(organizer["@type"]).to eq("Organization")
        expect(organizer["name"]).to eq(event.organiser.name)
      end
    end

    context "eventAttendanceMode" do
      it "is OfflineEventAttendanceMode for physical events" do
        expect(data["eventAttendanceMode"]).to eq("https://schema.org/OfflineEventAttendanceMode")
      end

      it "is OnlineEventAttendanceMode for online-only events" do
        online_event = create(:event, address: nil, online_address: create(:online_address),
                                      calendar: create(:calendar, strategy: "online_only"))
        result = online_event.to_json_ld(base_url: base_url)
        expect(result["eventAttendanceMode"]).to eq("https://schema.org/OnlineEventAttendanceMode")
      end

      it "is MixedEventAttendanceMode for hybrid events" do
        hybrid_event = create(:event, online_address: create(:online_address))
        result = hybrid_event.to_json_ld(base_url: base_url)
        expect(result["eventAttendanceMode"]).to eq("https://schema.org/MixedEventAttendanceMode")
      end
    end

    context "image" do
      it "uses organiser image when available" do
        organiser = event.organiser
        fake_image = instance_double(ImageUploader, url: "https://example.com/organiser.jpg")
        allow(organiser).to receive_messages(image?: true, image: fake_image)

        result = event.to_json_ld(base_url: base_url)
        expect(result["image"]).to eq("https://example.com/organiser.jpg")
      end

      it "falls back to partner_at_location image" do
        place = create(:partner)
        event_with_place = create(:event, place: place)
        fake_image = instance_double(ImageUploader, url: "https://example.com/venue.jpg")
        allow(event_with_place.organiser).to receive(:image?).and_return(false)
        allow(place).to receive_messages(image?: true, image: fake_image)

        result = event_with_place.to_json_ld(base_url: base_url)
        expect(result["image"]).to eq("https://example.com/venue.jpg")
      end

      it "omits image when no partner has one" do
        expect(data).not_to have_key("image")
      end
    end
  end
end
