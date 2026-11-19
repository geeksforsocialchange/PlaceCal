# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin calendar source links", type: :request do
  describe "GET /admin/calendars/resolve_source" do
    let(:link) { "https://lu.ma/london-pattern-club" }
    let(:feed) { "https://api.lu.ma/ics/get?entity=calendar&id=cal-8tfFZUVfInFAcNa" }

    def resolve(source)
      get resolve_source_admin_calendars_url(host: admin_host), params: { source: }, as: :json
    end

    it "turns away a signed-out visitor" do
      resolve(link)
      expect(response).to have_http_status(:unauthorized)
    end

    it "turns away a user who can't add calendars" do
      sign_in create(:citizen_user)
      resolve(link)
      expect(response).to redirect_to(admin_root_path)
    end

    %i[root_user partner_admin neighbourhood_admin].each do |role|
      it "answers a #{role.to_s.humanize(capitalize: false)} with the feed and its kind" do
        allow(CalendarSourceResolver).to receive(:call).with(link)
                                                       .and_return(CalendarSourceResolver::Result.new(kind: "luma", source: feed))
        sign_in create(role)
        resolve(link)

        expect(response.parsed_body).to eq("source" => feed, "kind" => "luma")
      end
    end

    it "answers with no source when the link can't be resolved" do
      allow(CalendarSourceResolver).to receive(:call).and_return(nil)
      sign_in create(:root_user)
      resolve("https://example.com/events")

      expect(response).to be_successful
      expect(response.parsed_body).to eq("source" => nil, "kind" => nil)
    end
  end
end
