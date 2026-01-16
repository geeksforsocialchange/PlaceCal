# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Accessibility", :slow, type: :system do
  include_context "admin login"

  # Create test data for pages that need it
  let!(:article) { create(:article) }
  let!(:partner) { create(:partner) }
  let!(:site) { create(:site) }
  let!(:tag) { create(:tag) }
  let!(:calendar) { create(:calendar, partner: partner) }
  let!(:neighbourhood) { create(:neighbourhood) }
  let!(:partnership) { create(:partnership) }
  let!(:collection) { create(:collection) }
  let!(:supporter) { create(:supporter) }

  def admin_url(path)
    port = Capybara.current_session.server.port
    "http://admin.lvh.me:#{port}#{path}"
  end

  describe "index pages" do
    it "dashboard has no accessibility violations" do
      visit admin_url("/")
      expect(page).to be_axe_clean
    end

    it "articles index has no accessibility violations" do
      visit admin_url("/articles")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "partners index has no accessibility violations" do
      visit admin_url("/partners")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "sites index has no accessibility violations" do
      visit admin_url("/sites")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "users index has no accessibility violations" do
      visit admin_url("/users")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "tags index has no accessibility violations" do
      visit admin_url("/tags")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "calendars index has no accessibility violations" do
      visit admin_url("/calendars")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "neighbourhoods index has no accessibility violations" do
      visit admin_url("/neighbourhoods")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "partnerships index has no accessibility violations" do
      visit admin_url("/partnerships")
      await_datatables
      expect(page).to be_axe_clean
    end

    it "collections index has no accessibility violations" do
      visit admin_url("/collections")
      expect(page).to be_axe_clean
    end

    it "supporters index has no accessibility violations" do
      visit admin_url("/supporters")
      expect(page).to be_axe_clean
    end
  end

  describe "edit forms" do
    it "article edit form has no accessibility violations" do
      visit admin_url("/articles/#{article.id}/edit")
      expect(page).to be_axe_clean
    end

    it "partner edit form has no accessibility violations" do
      visit admin_url("/partners/#{partner.id}/edit")
      expect(page).to be_axe_clean
    end

    it "site edit form has no accessibility violations" do
      visit admin_url("/sites/#{site.id}/edit")
      expect(page).to be_axe_clean
    end

    it "tag edit form has no accessibility violations" do
      visit admin_url("/tags/#{tag.id}/edit")
      expect(page).to be_axe_clean
    end

    it "calendar edit form has no accessibility violations" do
      visit admin_url("/calendars/#{calendar.id}/edit")
      expect(page).to be_axe_clean
    end

    it "neighbourhood edit form has no accessibility violations" do
      visit admin_url("/neighbourhoods/#{neighbourhood.id}/edit")
      expect(page).to be_axe_clean
    end

    it "user edit form has no accessibility violations" do
      visit admin_url("/users/#{admin_user.id}/edit")
      expect(page).to be_axe_clean
    end
  end

  describe "new forms" do
    it "new article form has no accessibility violations" do
      visit admin_url("/articles/new")
      expect(page).to be_axe_clean
    end

    it "new partner form has no accessibility violations" do
      visit admin_url("/partners/new")
      expect(page).to be_axe_clean
    end

    it "new tag form has no accessibility violations" do
      visit admin_url("/tags/new")
      expect(page).to be_axe_clean
    end

    it "new user form has no accessibility violations" do
      visit admin_url("/users/new")
      expect(page).to be_axe_clean
    end

    it "new calendar form has no accessibility violations" do
      visit admin_url("/calendars/new")
      expect(page).to be_axe_clean
    end
  end
end
