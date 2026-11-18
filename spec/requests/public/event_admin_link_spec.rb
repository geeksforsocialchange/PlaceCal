# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open in admin link on the public event page", type: :request do
  let(:ward) { create(:riverside_ward) }
  let(:organiser) { create(:partner, address: create(:address, neighbourhood: ward)) }
  let(:calendar) { create(:calendar, organiser:) }
  let(:event) { create(:event, calendar:, organiser:, address: organiser.address) }
  let(:site) { create(:site, slug: "core-site").tap { it.neighbourhoods << ward } }
  let(:admin_link) { admin_event_url(event, host: "admin.lvh.me") }

  def admin_links_on(host)
    get event_url(event, host:)
    Nokogiri::HTML(response.body).css(%(a[href="#{admin_link}"]))
  end

  it "is not shown to a signed-out visitor, who still gets the page" do
    expect(admin_links_on("#{site.slug}.lvh.me")).to be_empty
    expect(response).to have_http_status(:ok)
  end

  it "is not shown to an admin who cannot edit the event's calendar" do
    sign_in create(:partner_admin)

    expect(admin_links_on("#{site.slug}.lvh.me")).to be_empty
  end

  context "for a root user" do
    before { sign_in create(:root_user) }

    it "is shown on a site's event page" do
      expect(admin_links_on("#{site.slug}.lvh.me").map(&:text)).to eq([I18n.t("events.show.open_in_admin")])
    end

    it "is shown on the directory's event page" do
      expect(admin_links_on("lvh.me").map { it.text.strip }).to eq([I18n.t("events.show.open_in_admin")])
    end
  end

  it "is shown to an admin who can edit the event's calendar" do
    user = create(:partner_admin)
    calendar.update!(organiser: user.partners.first)
    sign_in user

    expect(admin_links_on("#{site.slug}.lvh.me")).not_to be_empty
  end
end
