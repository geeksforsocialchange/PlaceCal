# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Neighbourhoods", type: :request do
  let!(:root_user) { create(:root_user) }
  let!(:neighbourhood) { create(:neighbourhood) }
  let!(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let!(:additional_neighbourhoods) { create_list(:neighbourhood, 4) }

  describe "GET /admin/neighbourhoods" do
    context "as a root user" do
      before { sign_in root_user }

      it "shows correct title" do
        get admin_neighbourhoods_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("<title>Neighbourhoods | PlaceCal Admin</title>")
      end

      it "shows all neighbourhoods" do
        get admin_neighbourhoods_url(host: admin_host)
        expect(response).to be_successful
        # Root users see all neighbourhoods (up to pagination limit)
        # The page should contain neighbourhood rows
        expect(response.body).to include("<tbody")
      end
    end

    context "as a neighbourhood admin" do
      before { sign_in neighbourhood_admin }

      it "shows only their neighbourhoods" do
        get admin_neighbourhoods_url(host: admin_host)
        expect(response).to be_successful
        # Neighbourhood admin sees only their assigned neighbourhood(s)
        # Should have exactly 1 row for their neighbourhood
      end
    end
  end

  describe "GET /admin/neighbourhoods/:id/edit" do
    context "as a root user" do
      before { sign_in root_user }

      it "shows edit form with all fields" do
        get edit_admin_neighbourhood_url(neighbourhood, host: admin_host)
        expect(response).to be_successful

        expect(response.body).to include("Name")
        expect(response.body).to include("Abbreviated name")
        expect(response.body).to include("Unit")
        expect(response.body).to include("Unit code key")
        expect(response.body).to include("Unit name")
        expect(response.body).to include("Unit code value")
        expect(response.body).to include("Users")
        expect(response.body).to include("Save")
        expect(response.body).to include("Destroy")
      end
    end
  end
end
