# frozen_string_literal: true

require "rails_helper"

# axe's heading-order rule: a page must not skip a heading level. Site pages
# used to go h2 (the navigation's screen-reader site name) then h4 (the hero
# tagline) then h1, and the partner and event bodies opened at h3.
#
# Two neighbouring axe rules ride along here, because they are cheap to assert
# from the same documents: landmark-unique (every nav landmark needs an
# accessible name) and duplicate-id.
RSpec.describe "Site page heading order", type: :request do
  let(:site) { create(:site, slug: "headings", tagline: "Events in Riverside") }
  let(:ward) { create(:riverside_ward) }
  let(:partner) { create(:riverside_partner, address: create(:riverside_address, neighbourhood: ward)) }

  before { site.neighbourhoods << ward }

  def document
    Nokogiri::HTML(response.body)
  end

  def headings(scope = "body")
    document.css("#{scope} h1, #{scope} h2, #{scope} h3, #{scope} h4, #{scope} h5, #{scope} h6")
            .map(&:name)
  end

  describe "a partner page" do
    before { get partner_url(partner, host: "#{site.slug}.lvh.me") }

    it "renders the hero tagline as a paragraph, not a heading" do
      expect(response.body).to include(site.tagline)
      expect(document.at_css(".hero p.allcaps")&.text).to eq(site.tagline)
      expect(document.css(".hero h4")).to be_empty
    end

    it "puts only the site name h2 before the h1" do
      before_h1 = headings.take_while { |name| name != "h1" }

      expect(before_h1).to eq(["h2"])
    end

    # The shared footer has its own long-standing level jump, so the body of
    # the page is what this checks.
    it "never skips a heading level in the page body" do
      expect(skipped_levels(headings("main"))).to be_empty
    end
  end

  describe "an event page" do
    let(:event) do
      create(:event, address: create(:riverside_address, neighbourhood: ward), organiser: partner)
    end

    before { get event_url(event, host: "#{site.slug}.lvh.me") }

    it "never skips a heading level in the page body" do
      expect(response).to be_successful
      expect(skipped_levels(headings("main"))).to be_empty
    end
  end

  # The listing pages and the homepage, which the show pages above do not
  # reach: each has its own hero and its own first body heading.
  describe "the listing pages and the homepage" do
    # Two child neighbourhoods with events of their own, so /events renders the
    # neighbourhood filter alongside the date picker: those two forms carry the
    # same period/sort/repeating fields and used to collide on their ids.
    let(:north) { create(:neighbourhood, name: "Riverside North", unit: "ward", parent: ward) }
    let(:south) { create(:neighbourhood, name: "Riverside South", unit: "ward", parent: ward) }
    let!(:event) do
      create(:event, address: create(:riverside_address, neighbourhood: north), organiser: partner,
                     dtstart: 1.day.from_now)
    end
    let!(:southern_event) do
      create(:event, address: create(:riverside_address, neighbourhood: south),
                     organiser: create(:partner, address: create(:riverside_address, neighbourhood: south)),
                     dtstart: 1.day.from_now)
    end
    let!(:article) { create(:article, is_draft: false) }

    {
      "the homepage" => "/",
      "the partners index" => "/partners",
      "the events index" => "/events",
      "the news index" => "/news"
    }.each do |name, path|
      context "on #{name}" do
        before { get "http://#{site.slug}.lvh.me#{path}" }

        it "responds successfully" do
          expect(response).to be_successful
        end

        it "never skips a heading level in the page body" do
          expect(skipped_levels(headings("main"))).to be_empty
        end

        it "names every navigation landmark" do
          expect(unnamed_navs).to be_empty
        end

        it "uses every id at most once" do
          expect(duplicate_ids).to be_empty
        end
      end
    end

    context "on an article page" do
      before { get news_url(article, host: "#{site.slug}.lvh.me") }

      it "renders the byline as a paragraph, not a heading" do
        expect(response).to be_successful
        expect(document.at_css("p.article__author")).to be_present
        expect(document.at_css("h3.article__author")).to be_nil
      end

      it "never skips a heading level in the page body" do
        expect(skipped_levels(headings("main"))).to be_empty
      end
    end
  end

  describe "the mobile menu disclosure" do
    before { get "http://#{site.slug}.lvh.me/" }

    it "reports its state and names the menu it controls" do
      toggle = document.at_css(".header__toggle")

      expect(toggle["aria-expanded"]).to eq("false")
      expect(document.at_css("##{toggle['aria-controls']}")).to be_present
    end
  end

  # Every place the document jumps down by more than one level, as "h2 -> h4".
  def skipped_levels(names)
    levels = names.map { |name| name[1].to_i }
    levels.each_cons(2).filter_map { |from, to| "h#{from} -> h#{to}" if to > from + 1 }
  end

  # A nav landmark has an accessible name from aria-label, or from the element
  # aria-labelledby points at. Anything else shows up as a bare "navigation"
  # in a screen reader's landmark menu.
  def unnamed_navs
    doc = document
    unnamed = doc.css("nav").reject do |nav|
      nav["aria-label"].present? ||
        (nav["aria-labelledby"].present? && doc.at_css("##{nav['aria-labelledby']}").present?)
    end

    unnamed.map { |nav| nav["class"] }
  end

  # Ids inside inlined SVGs are excluded: two Sketch exports on the same page
  # collide on names like "Fill-11", none of them referenced by a url(#…), and
  # fixing that means re-exporting the artwork rather than changing markup.
  def duplicate_ids
    ids = document.css("[id]").reject { |node| node.ancestors("svg").any? }.map { |node| node["id"] }

    ids.tally.select { |_id, count| count > 1 }.keys
  end
end
