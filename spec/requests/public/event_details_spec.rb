# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Event page details on core and extension themes", type: :request do
  let(:ward) { create(:riverside_ward) }
  let(:address) { create(:address, neighbourhood: ward) }
  let(:organiser) { create(:partner, name: "Oldtown Library", address:) }
  let(:venue) { create(:partner, name: "Harbourside Arts Centre", address:) }
  let(:event) { create(:event, organiser:, place: venue, address:, dtstart: 1.day.from_now, dtend: 1.day.from_now + 2.hours) }

  def details_for(site)
    site.neighbourhoods << ward
    get event_url(event, host: "#{site.slug}.lvh.me")
    Nokogiri::HTML(response.body)
  end

  def part(html, name) = html.at_css(%([data-scope="event-details"][data-part="#{name}"]))

  context "with a core theme" do
    let(:site) { create(:site, slug: "core-site") }

    it "has no byline, keeps the organiser's name out of the contact details, and names the venue above the address",
       :aggregate_failures do
      html = details_for(site)

      expect(html.at_css('[data-scope="hero"][data-part="standfirst"]')).to be_nil
      expect(part(html, "contact-name")).to be_nil
      expect(part(html, "contact").at_css('a[href^="/partners/"]')).to be_nil
      expect(part(html, "address").at_css(%([data-part="venue"] a[href="/partners/#{venue.to_param}"]))).to be_present
      expect(response.body).not_to match(%r{<h2[^>]*>Venue</h2>})
    end

    it "heads the address with the organiser, then a different venue, and shows the map in the sidebar instead of an organiser section",
       :aggregate_failures do
      html = details_for(site)
      address_section = part(html, "address")

      expect(address_section.css('[data-part="organiser-name"] a, [data-part="venue"] a').map(&:text)).to eq(["Oldtown Library", "Harbourside Arts Centre"])
      expect(address_section.at_css('[data-part="organiser-name"]').text).to eq("By Oldtown Library")
      expect(part(html, "organiser")).to be_nil
      expect(part(html, "aside").at_css('[data-scope="map"]')).to be_present
    end

    it "names the organiser once when the event is at the organiser's own building" do
      event.update!(place: organiser)
      address_section = part(details_for(site), "address")

      expect(address_section.at_css('[data-part="organiser-name"] a')&.text).to eq("Oldtown Library")
      expect(address_section.at_css('[data-part="venue"]')).to be_nil
    end

    it "leaves out the venue line when the venue is hidden" do
      venue.update_columns(hidden: true) # rubocop:disable Rails/SkipsModelValidations

      expect(part(details_for(site), "address").at_css('[data-part="venue"]')).to be_nil
    end

    it "leaves out Get in touch when the organiser has no contact details" do
      organiser.update_columns(public_email: nil, public_phone: nil, url: nil, social_links: []) # rubocop:disable Rails/SkipsModelValidations

      expect(part(details_for(site), "contact")).to be_nil
    end

    it "puts a meeting link in an Online section above the location, with a filled join button", :aggregate_failures do
      event.update!(online_address: create(:direct_online_address))
      html = details_for(site)

      online = part(html, "online")
      expect(online.text).to include("On Zoom")
      expect(online.at_css('a[data-variant="primary"][href="https://zoom.us/j/1234567890"]').text).to eq("Join on Zoom")
      expect(part(html, "links").at_css('a[href="https://zoom.us/j/1234567890"]')).to be_nil
      expect(html.css('[data-scope="event-details"][data-part="online"] ~ [data-part="address"]')).to be_present
    end

    it "says the joining details are on the linked page when the link is not the meeting itself", :aggregate_failures do
      event.update!(online_address: create(:online_address, url: "https://example.org/register"))
      online = part(details_for(site), "online")

      expect(online.at_css('[data-part="online-note"]')).to be_present
      expect(online.at_css('a[href="https://example.org/register"]').text).to eq("Visit the webpage for this event")
    end

    it "leaves out Event location for an online event with no address, even when its feed gave the meeting link as the location" do
      event.update!(online_address: create(:direct_online_address), address: nil, place: nil,
                    raw_location_from_source: "https://zoom.us/j/1234567890")

      expect(part(details_for(site), "address")).to be_nil
    end

    it "keeps Event location for an online event whose feed names a place without an address" do
      event.update!(online_address: create(:direct_online_address), address: nil, place: nil, raw_location_from_source: "The Town Hall")

      expect(part(details_for(site), "address").text).to include("The Town Hall")
    end
  end

  context "with an extension theme" do
    let(:site) { create(:site, slug: "td-site", theme: "transdimension") }

    it "keeps the byline, the contact name and the separate Venue section", :aggregate_failures do
      html = details_for(site)

      expect(html.at_css('[data-scope="hero"][data-part="standfirst"]')&.text).to include("By Oldtown Library")
      expect(part(html, "contact-name")&.text).to eq("Oldtown Library")
      expect(part(html, "venue").at_css("h2")&.text).to eq("Venue")
      expect(part(html, "address").at_css('[data-part="venue"]')).to be_nil
    end
  end
end
