# frozen_string_literal: true

require "rails_helper"

# Pages to check on each host; the site's are relative to its host.
module MetaTagPages
  DIRECTORY = {
    "the homepage" => -> { "http://lvh.me/" },
    "our story" => -> { "http://lvh.me/our-story" },
    "get in touch" => -> { "http://lvh.me/get-in-touch" },
    "the privacy policy" => -> { "http://lvh.me/privacy" },
    "the terms of use" => -> { "http://lvh.me/terms-of-use" },
    "the sustainability page" => -> { "http://lvh.me/sustainability" },
    "the accessibility statement" => -> { "http://lvh.me/accessibility" },
    "the MCP page" => -> { "http://lvh.me/mcp" },
    "the events listing" => -> { "http://lvh.me/events" },
    "the partners listing" => -> { "http://lvh.me/partners" },
    "the partnerships listing" => -> { "http://lvh.me/partnerships" }
  }.freeze
  JOIN = {
    "the homepage" => -> { "http://join.lvh.me/" },
    "the audiences index" => -> { "http://join.lvh.me/who-its-for" },
    "an audience page" => -> { "http://join.lvh.me/who-its-for/community-groups" },
    "the features page" => -> { "http://join.lvh.me/features" },
    "our story" => -> { "http://join.lvh.me/our-story" },
    "the pricing page" => -> { "http://join.lvh.me/pricing" },
    "the book a demo page" => -> { "http://join.lvh.me/book-a-demo" }
  }.freeze
  SITE = {
    "the homepage" => -> { "#{host}/" },
    "the events listing" => -> { "#{host}/events" },
    "the partners listing" => -> { "#{host}/partners" },
    "the news listing" => -> { "#{host}/news" },
    "get in touch" => -> { "#{host}/get-in-touch" },
    "the privacy policy" => -> { "#{host}/privacy" }
  }.freeze
end

# The description and share image every public page sends to search engines and link previews (#3939).
RSpec.describe "Public page meta tags", type: :request do
  include_context "normal island data"

  def head_meta(attribute, name)
    node = Nokogiri::HTML(response.body).at_css("meta[#{attribute}='#{name}']")
    node && node["content"]
  end

  def description = head_meta("name", "description")

  def directory_card = %r{\A#{Regexp.escape(Site::DIRECTORY_URL.chomp('/'))}/opengraph\.png\z}

  shared_examples "a page with its own meta tags" do |pages, image:|
    pages.each do |name, path|
      it "describes #{name} and gives it a share image" do
        get instance_exec(&path), headers: { "Accept" => "text/html" }

        expect(response).to have_http_status(:ok)
        expect(description).to be_present
        expect(description).to eq(description.squish)
        expect(description.length).to be <= 160
        expect(description).not_to include("%{")
        expect(head_meta("property", "og:description")).to eq(description)
        expect(head_meta("property", "og:image")).to match(instance_exec(&image))
      end
    end
  end

  describe "the directory, with no site" do
    it_behaves_like "a page with its own meta tags", MetaTagPages::DIRECTORY, image: -> { directory_card }

    it "gives every one of those pages a description of its own" do
      descriptions = MetaTagPages::DIRECTORY.values.map do |path|
        get instance_exec(&path), headers: { "Accept" => "text/html" }
        description
      end

      expect(descriptions.uniq.size).to eq(descriptions.size)
    end

    it "falls back to directory copy, not a sentence with a missing site name" do
      get "http://lvh.me/our-story"

      expect(description).not_to start_with(" ")
      expect(description).not_to eq(I18n.t("meta.description", site: nil).squish)
    end

    it "uses the generated 1200 by 630 card" do
      get "http://lvh.me/privacy"

      expect(head_meta("property", "og:image:width")).to eq("1200")
      expect(head_meta("property", "og:image:height")).to eq("630")
    end

    it "cuts a long partnership description down to plain text" do
      partnership_site.update!(description: "#{'A long paragraph about the partnership. ' * 10}\n\nAnd **another**.")
      get "http://lvh.me/partnerships/#{partnership_site.slug}"

      expect(description.length).to be <= 160
      expect(description).not_to include("\n", "**")
    end
  end

  describe "the join site" do
    it_behaves_like "a page with its own meta tags", MetaTagPages::JOIN, image: -> { directory_card }
  end

  describe "a site" do
    let(:host) { "http://#{millbrook_site.slug}.lvh.me" }

    it_behaves_like "a page with its own meta tags", MetaTagPages::SITE, image: -> { %r{\A#{host}/opengraph\.png\z} }

    it "describes its listing pages differently from its homepage" do
      descriptions = %w[/ /events /partners /news].map do |path|
        get "#{host}#{path}"
        description
      end

      expect(descriptions.uniq.size).to eq(4)
    end

    it "names the site, not PlaceCal, in an event's share image alt text" do
      get "#{host}/events/#{event_one.id}"

      expect(head_meta("property", "og:image:alt")).to eq(I18n.t("og_image.alt.event", name: event_one.summary,
                                                                                       site: millbrook_site.name))
    end
  end

  describe "an event with no description" do
    it "is described by what, when and who" do
      event_one.update!(description: "", dtstart: Time.zone.local(2030, 6, 3, 10), dtend: Time.zone.local(2030, 6, 3, 12))
      get "http://lvh.me/events/#{event_one.id}"

      expect(description).to start_with("Community Coffee Morning on Monday 3 June")
      expect(description).to include(riverside_hub.name)
    end
  end
end
