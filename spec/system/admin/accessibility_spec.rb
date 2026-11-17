# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Accessibility", :slow, type: :system do
  include_context "admin login"

  let(:image) { Rails.root.join("spec/fixtures/files/test_image.jpg") }
  let(:ward) { create(:neighbourhood) }
  let(:editor) { create(:user, first_name: "Edie", last_name: "Tor", avatar: File.open(image)) }

  let!(:partner) do
    create(:riverside_community_hub, image: File.open(image)).tap do |p|
      create(:service_area, partner: p, neighbourhood: ward)
      p.users << editor
    end
  end
  let!(:calendar) { create(:calendar, organiser: partner, place: partner) }
  let!(:event) { create(:event, organiser: partner, calendar:) }
  let!(:site) do
    create(:site, site_admin: editor, hero_image: File.open(image)).tap do |s|
      s.neighbourhoods << ward
    end
  end
  let!(:partnership) { create(:partnership).tap { |t| t.partners << partner } }
  let!(:tag) { create(:tag).tap { |t| t.partners << partner } }
  let!(:article) { create(:article, author: editor, article_image: File.open(image)).tap { |a| a.partners << partner } }
  let!(:supporter) { create(:supporter) }

  # axe skips hidden panels, so each tab of a tabbed form is checked on its own.
  def expect_every_tab_axe_clean
    expect(page).to be_axe_clean
    # Tabs render with the page, so don't let `all` wait out its timeout on a form without them
    tab_count = all("input.tab[type=radio]", wait: false).size
    tab_count.times do |index|
      tab = all("input.tab[type=radio]")[index]
      aggregate_failures("tab #{tab['aria-label']}") do
        tab.click
        expect(page).to have_css("input.tab[type=radio]:checked[aria-label='#{tab['aria-label']}']")
        expect(page).to be_axe_clean
      end
    end
  end

  {
    "dashboard" => "/",
    "partners index" => "/partners",
    "calendars index" => "/calendars",
    "users index" => "/users",
    "sites index" => "/sites",
    "neighbourhoods index" => "/neighbourhoods",
    "partnerships index" => "/partnerships",
    "tags index" => "/tags",
    "articles index" => "/articles",
    "supporters index" => "/supporters",
    "jobs" => "/jobs"
  }.each do |name, path|
    it "#{name} has no accessibility violations" do
      visit admin_url(path)
      await_datatables if page.has_css?("[data-controller~='admin-table']", wait: 0)
      expect(page).to be_axe_clean
    end
  end

  {
    "calendar page" => -> { "/calendars/#{calendar.id}" },
    "site page" => -> { "/sites/#{site.id}" },
    "neighbourhood page" => -> { "/neighbourhoods/#{ward.id}" },
    "partner edit form" => -> { "/partners/#{partner.id}/edit" },
    "calendar edit form" => -> { "/calendars/#{calendar.id}/edit" },
    "user edit form" => -> { "/users/#{editor.id}/edit" },
    "profile" => -> { "/profile" },
    "site edit form" => -> { "/sites/#{site.id}/edit" },
    "neighbourhood edit form" => -> { "/neighbourhoods/#{ward.id}/edit" },
    "partnership edit form" => -> { "/partnerships/#{partnership.id}/edit" },
    "tag edit form" => -> { "/tags/#{tag.id}/edit" },
    "article edit form" => -> { "/articles/#{article.id}/edit" },
    "supporter edit form" => -> { "/supporters/#{supporter.id}/edit" },
    "new partner form" => -> { "/partners/new" },
    "new calendar form" => -> { "/calendars/new" },
    "new user form" => -> { "/users/new" },
    "new site form" => -> { "/sites/new" },
    "new partnership form" => -> { "/partnerships/new" },
    "new tag form" => -> { "/tags/new" },
    "new article form" => -> { "/articles/new" },
    "new supporter form" => -> { "/supporters/new" }
  }.each do |name, path|
    it "#{name} has no accessibility violations on any tab" do
      visit admin_url(instance_exec(&path))
      expect_every_tab_axe_clean
    end
  end

  describe "signed out pages" do
    before { click_button I18n.t("admin.topbar.sign_out") }

    it "sign in page has no accessibility violations" do
      visit public_url("/users/sign_in")
      expect(page).to be_axe_clean
    end

    it "password reset page has no accessibility violations" do
      visit public_url("/users/password/new")
      expect(page).to be_axe_clean
    end

    it "invitation page has no accessibility violations" do
      token = create(:user).tap(&:invite!).raw_invitation_token
      visit public_url("/users/invitation/accept?invitation_token=#{token}")
      expect(page).to be_axe_clean
    end
  end
end
