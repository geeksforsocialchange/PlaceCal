# frozen_string_literal: true

require "rails_helper"

# Regression test for #2144: the "you need to sign in" flash warning that is
# shown when an unauthenticated user tries to access /admin must NOT persist
# onto the next page they visit.
RSpec.describe "Admin authentication flash", type: :request do
  let!(:published_site) { create(:site, is_published: true) }

  let(:warning_message) do
    I18n.t("devise.failure.unauthenticated")
  end

  describe "unauthenticated access to /admin" do
    it "redirects to the sign in page" do
      get "http://#{admin_host}"
      expect(response).to redirect_to("http://#{admin_host}/users/sign_in")
    end

    it "sets the warning flash for the redirect target" do
      get "http://#{admin_host}"
      expect(flash[:danger] || flash[:alert]).to eq(warning_message)
    end

    it "does not persist the warning flash onto the next visited page" do
      # 1. Unauthenticated visit to admin sets the warning flash and redirects.
      get "http://#{admin_host}"
      expect(flash[:danger] || flash[:alert]).to eq(warning_message)

      # 2. Instead of following the redirect to the sign-in page, the user
      #    navigates to a different page (e.g. a public site). The warning
      #    must not still be present on that request.
      get "http://#{published_site.slug}.lvh.me/robots.txt"
      expect(response).to be_successful
      expect(flash[:danger]).to be_blank
      expect(flash[:alert]).to be_blank
    end
  end

  # The fix must not strip flash[:alert] that admin pages set for themselves
  # (e.g. a Pundit "Unable to access" message), since admin pages render it.
  describe "admin pages keep their own alert flash" do
    let(:citizen) { create(:citizen_user) }
    let!(:partner) { create(:partner) }

    before { sign_in citizen }

    it "preserves an admin-set alert across an admin request" do
      # A citizen lacks permission, so Pundit sets flash[:alert] = "Unable to
      # access" and redirects to the admin partners index.
      get "http://#{admin_host}/partners/#{partner.id}/edit"
      expect(flash[:alert]).to eq("Unable to access")

      # The alert must survive to the admin index it redirects to. Request the
      # JSON datatable variant (it skips the asset-heavy HTML layout).
      get "http://#{admin_host}/partners",
          params: { draw: "1", start: "0", length: "25" },
          headers: { "Accept" => "application/json" }
      expect(flash[:alert]).to eq("Unable to access")
    end
  end
end
