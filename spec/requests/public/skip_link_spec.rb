# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Skip to main content link", type: :request do
  let(:site) { create(:site, slug: "skiplink") }

  {
    "a site" => "http://skiplink.lvh.me/",
    "the directory" => "http://lvh.me/",
    "the join site" => "http://join.lvh.me/"
  }.each do |name, url|
    context "on #{name}" do
      before do
        site
        get url
      end

      let(:document) { Nokogiri::HTML(response.body) }

      it "is the first focusable element in the body" do
        first_focusable = document.at_css("body a[href], body button, body input, body select, body textarea, body [tabindex]:not([tabindex='-1'])")

        expect(first_focusable["href"]).to eq("#main-content")
        expect(first_focusable.text).to eq(I18n.t("navigation.skip_to_content"))
      end

      it "points at the main element, which can take focus" do
        main = document.at_css("main#main-content")

        expect(main).to be_present
        expect(main["tabindex"]).to eq("-1")
      end
    end
  end
end
