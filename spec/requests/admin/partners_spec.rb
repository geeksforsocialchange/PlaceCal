# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Partners", type: :request do
  describe "GET /admin/partners" do
    context "as an unauthenticated user" do
      it "redirects to login" do
        get admin_partners_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a citizen user" do
      let(:user) { create(:citizen_user) }

      before { sign_in user }

      it "shows empty partner list (no access to any partners)" do
        # Citizens can access the page but see an empty list via policy_scope
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
      end
    end

    context "as a root user" do
      let(:user) { create(:root_user) }
      let!(:partner1) { create(:partner) }
      let!(:partner2) { create(:partner) }

      before { sign_in user }

      it "shows partners index page with datatable" do
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("Partners") # Page title
        expect(response.body).to include("data-controller=\"admin-table\"") # Datatable
        expect(response.body).to include(admin_partners_path(format: :json)) # JSON source
      end

      it "includes add new partner button" do
        get admin_partners_url(host: admin_host)
        expect(response.body).to include("Add Partner")
      end
    end

    context "as a partner admin" do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }
      let!(:other_partner) { create(:partner) }

      before { sign_in user }

      it "shows partners index page with datatable" do
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("data-controller=\"admin-table\"")
        expect(response.body).to include(admin_partners_path(format: :json)) # JSON source
      end
    end

    context "as a neighbourhood admin" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      # Must use same ward instance - :riverside_address creates NEW ward via association
      let!(:partner_in_neighbourhood) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end
      let!(:partner_outside_neighbourhood) do
        address = create(:oldtown_address)
        create(:partner, address: address)
      end

      before { sign_in user }

      it "shows partners index page with datatable" do
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("data-controller=\"admin-table\"")
        expect(response.body).to include(admin_partners_path(format: :json)) # JSON source
      end
    end
  end

  describe "GET /admin/partners/:id" do
    let(:partner) { create(:riverside_partner) }

    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "redirects to edit page" do
        # show action redirects to edit
        get admin_partner_url(partner, host: admin_host)
        expect(response).to redirect_to(edit_admin_partner_url(partner, host: admin_host))
      end
    end

    context "as a partner admin for this partner" do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }

      before { sign_in user }

      it "redirects to edit page" do
        # show action redirects to edit
        get admin_partner_url(partner, host: admin_host)
        expect(response).to redirect_to(edit_admin_partner_url(partner, host: admin_host))
      end
    end

    context "as a partner admin for a different partner" do
      let(:user) { create(:partner_admin) }
      let(:other_partner) { create(:partner) }

      before { sign_in user }

      it "denies access" do
        get admin_partner_url(other_partner, host: admin_host)
        expect(response).to have_http_status(:forbidden).or redirect_to(admin_partners_path)
      end
    end
  end

  describe "GET /admin/partners/new" do
    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "shows the new partner form" do
        get new_admin_partner_url(host: admin_host)
        expect(response).to be_successful
      end
    end

    context "as a neighbourhood admin" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

      before { sign_in user }

      it "shows the new partner form" do
        get new_admin_partner_url(host: admin_host)
        expect(response).to be_successful
      end
    end

    context "as a partner admin" do
      let(:user) { create(:partner_admin) }

      before { sign_in user }

      it "denies access" do
        get new_admin_partner_url(host: admin_host)
        expect(response).to have_http_status(:forbidden).or redirect_to(admin_partners_path)
      end
    end
  end

  describe "GET /admin/partners/:id/edit" do
    let(:partner) { create(:riverside_partner) }

    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "shows the edit form" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response).to be_successful
      end
    end

    context "as a partner admin for this partner" do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }

      before { sign_in user }

      it "shows the edit form" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response).to be_successful
      end
    end

    context "edit form content" do
      let(:user) { create(:root_user) }
      let(:partner) { create(:riverside_partner) }

      before { sign_in user }

      it "has correct page title and heading" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("<title>Editing #{partner.name} | PlaceCal Admin</title>")
        expect(response.body).to include("Edit Partner: <em>#{partner.name}</em>")
      end

      it "has basic information section with required labels" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("Basic Information")
        expect(response.body).to include("Name")
        expect(response.body).to include("Summary")
        expect(response.body).to include("Description")
        expect(response.body).to include("Image")
        expect(response.body).to include("Website address")
        expect(response.body).to include("Twitter handle")
      end

      it "has address section with required labels" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("Address")
        expect(response.body).to include("Street address")
        expect(response.body).to include("City")
        expect(response.body).to include("Postcode")
      end

      it "has contact information section" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("Contact Information")
        expect(response.body).to include("Public Contact")
        expect(response.body).to include("Public name")
        expect(response.body).to include("Public email")
        expect(response.body).to include("Public phone")
        expect(response.body).to include("Partnership Contact")
        expect(response.body).to include("Partner name")
        expect(response.body).to include("Partner email")
        expect(response.body).to include("Partner phone")
      end

      it "has delete button for root users" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("destroy-partner")
        expect(response.body).to include("Delete Partner")
      end
    end

    context "delete button visibility for neighbourhood admins" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let(:partner) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end

      before { sign_in user }

      it "shows delete button" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("destroy-partner")
        expect(response.body).to include("Delete Partner")
      end
    end

    context "hidden partner reason" do
      let(:admin) { create(:root_user) }
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }
      let(:reason) { "This is bad content for PlaceCal" }

      before do
        partner.update!(hidden: true, hidden_reason: reason, hidden_blame_id: admin.id)
        sign_in user
      end

      it "shows hidden reason to partner admin" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("hidden-reason")
        expect(response.body).to include(reason)
      end
    end
  end

  describe "PUT /admin/partners/:id" do
    context "bad image upload" do
      let(:user) { create(:root_user) }
      let(:partner) { create(:riverside_partner) }

      before { sign_in user }

      it "shows error for invalid image type" do
        partner_params = {
          name: partner.name,
          address_attributes: {
            street_address: partner.address.street_address,
            postcode: partner.address.postcode
          },
          image: fixture_file_upload("bad-cat-picture.bmp")
        }

        put admin_partner_url(partner, host: admin_host), params: { partner: partner_params }

        expect(response).not_to be_redirect
        expect(response.body).to include("error prohibited this Partner from being saved")
        expect(response.body).to include("You are not allowed to upload")
        expect(response.body).to include("bmp")
      end
    end

    context "neighbourhood admin address restriction" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let(:partner) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end

      before { sign_in user }

      it "prevents updating address outside their neighbourhood" do
        # Create a different neighbourhood for the new address
        other_ward = create(:oldtown_ward)

        partner_params = {
          name: partner.name,
          address_attributes: {
            street_address: partner.address.street_address,
            postcode: "ZZAD 1HC" # Hillcrest postcode
          }
        }

        put admin_partner_url(partner, host: admin_host), params: { partner: partner_params }

        expect(response.body).to include("Partners cannot have an address outside of your ward")
      end
    end
  end
end
