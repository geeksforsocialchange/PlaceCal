# frozen_string_literal: true

require "rails_helper"

# axe's heading-order rule: a page must not skip a heading level. Site pages
# used to go h2 (the navigation's screen-reader site name) then h4 (the hero
# tagline) then h1, and the partner and event bodies opened at h3.
RSpec.describe "Site page heading order", type: :request do
  let(:site) { create(:site, slug: "headings", tagline: "Events in Riverside") }
  let(:ward) { create(:riverside_ward) }
  let(:partner) { create(:riverside_partner, address: create(:riverside_address, neighbourhood: ward)) }

  before { site.neighbourhoods << ward }

  def headings(scope = "body")
    Nokogiri::HTML(response.body).css("#{scope} h1, #{scope} h2, #{scope} h3, #{scope} h4, #{scope} h5, #{scope} h6")
            .map(&:name)
  end

  describe "a partner page" do
    before { get partner_url(partner, host: "#{site.slug}.lvh.me") }

    it "renders the hero tagline as a paragraph, not a heading" do
      expect(response.body).to include(site.tagline)
      expect(Nokogiri::HTML(response.body).at_css(".hero p.allcaps")&.text).to eq(site.tagline)
      expect(Nokogiri::HTML(response.body).css(".hero h4")).to be_empty
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

  # Every place the document jumps down by more than one level, as "h2 -> h4".
  def skipped_levels(names)
    levels = names.map { |name| name[1].to_i }
    levels.each_cons(2).filter_map { |from, to| "h#{from} -> h#{to}" if to > from + 1 }
  end
end
