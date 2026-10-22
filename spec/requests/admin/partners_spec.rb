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
        create(:partner, address:)
      end
      let!(:partner_outside_neighbourhood) do
        address = create(:oldtown_address)
        create(:partner, address:)
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
        expect(response.body).to include("<title>Edit Partner: #{partner.name} | PlaceCal Admin</title>")
        expect(response.body).to include("Edit Partner")
        expect(response.body).to include(partner.name)
      end

      it "has basic information section with required labels" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("Basic Information")
        expect(response.body).to include("Partner Name")
        expect(response.body).to include("Summary")
        expect(response.body).to include("Description")
        expect(response.body).to include("Partner Image")
        expect(response.body).to include("Website")
      end

      it "has address section with required labels" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("Address")
        expect(response.body).to include("Street Address")
        expect(response.body).to include("City")
        expect(response.body).to include("Postcode")
      end

      it "has contact information section" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("Public Contact")
        expect(response.body).to include("Partnership Contact")
      end

      it "has delete button for root users" do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response.body).to include("Delete Partner")
      end
    end

    context "delete button visibility for neighbourhood admins" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let(:partner) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address:)
      end

      before { sign_in user }

      it "shows delete button" do
        get edit_admin_partner_url(partner, host: admin_host)
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
        expect(response.body).to include("This partner is hidden")
        expect(response.body).to include(reason)
      end
    end
  end

  describe "assigning yourself as a partner admin" do
    let(:ward) { create(:riverside_ward) }
    let(:partner) { create(:partner, address: create(:address, neighbourhood: ward)) }
    let(:site) { create(:site, site_admin: user) }

    before do
      create(:sites_neighbourhood, site:, neighbourhood: ward)
      sign_in user
    end

    def add_self_as_admin(target)
      put admin_partner_url(target, host: admin_host),
          params: { partner: { name: target.name, user_ids: ["", user.id.to_s] } }
    end

    context "as a site admin who is a neighbourhood admin for the partner" do
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

      it "lists every other user by name, with the full list shown in the dropdown" do
        get edit_admin_partner_url(partner, host: admin_host)

        select = Nokogiri::HTML(response.body).at_css('select[data-stacked-list-selector-target="select"]')
        expect(select["data-tom-select-show-all-value"]).to eq("true")
        expect(select.css("option").map(&:text)).to include(user.display_name)
      end

      it "saves them as an admin" do
        add_self_as_admin(partner)

        expect(response).to redirect_to(edit_admin_partner_url(partner, host: admin_host))
        expect(partner.reload.users).to include(user)
      end

      it "refuses a partner outside their neighbourhood" do
        outside_partner = create(:partner, address: create(:oldtown_address))

        add_self_as_admin(outside_partner)

        expect(response).to redirect_to(admin_partners_url(host: admin_host))
        expect(outside_partner.reload.users).not_to include(user)
      end
    end

    context "as a site admin with no other admin role" do
      let(:user) { create(:citizen_user) }

      it "refuses, because site admins cannot edit partners" do
        add_self_as_admin(partner)

        expect(response).to redirect_to(admin_partners_url(host: admin_host))
        expect(partner.reload.users).not_to include(user)
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

    context "custom slug with a validation failure (#2358)" do
      let(:user) { create(:root_user) }
      let!(:other_partner) { create(:partner, slug: "taken-slug") }
      let(:partner) { create(:riverside_partner) }

      before { sign_in user }

      it "re-renders the form with the slug the user entered, not the original" do
        original_slug = partner.slug

        partner_params = {
          name: partner.name,
          slug: "taken-slug", # already used => slug validation fails
          address_attributes: {
            street_address: partner.address.street_address,
            postcode: partner.address.postcode
          }
        }

        put admin_partner_url(partner, host: admin_host), params: { partner: partner_params }

        expect(response).not_to be_redirect
        expect(response.body).to include('value="taken-slug"')
        expect(response.body).not_to include("value=\"#{original_slug}\"")
        expect(partner.reload.slug).to eq(original_slug)
      end
    end

    context "neighbourhood admin address restriction" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let(:partner) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address:)
      end

      before { sign_in user }

      it "prevents updating address outside their neighbourhood" do
        # Create a different neighbourhood for the new address
        create(:oldtown_ward)

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

    context "neighbourhood admin service area removal" do
      let(:ward) { create(:riverside_ward) }
      let(:outside_ward) { create(:hillcrest_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let(:partner) do
        partner = build(:partner, address: nil)
        partner.service_areas.build(neighbourhood: ward)
        partner.service_areas.build(neighbourhood: outside_ward)
        partner.save!
        partner
      end

      before { sign_in user }

      it "keeps the area when the remaining areas are outside their neighbourhoods" do
        service_area = partner.service_areas.find_by(neighbourhood: ward)

        put admin_partner_url(partner, host: admin_host), params: {
          partner: {
            name: partner.name,
            service_areas_attributes: {
              "0" => { id: service_area.id, neighbourhood_id: ward.id, _destroy: "1" },
              "1" => { id: partner.service_areas.find_by(neighbourhood: outside_ward).id,
                       neighbourhood_id: outside_ward.id, _destroy: "false" }
            }
          }
        }

        expect(response).to redirect_to(edit_admin_partner_url(partner, host: admin_host))
        expect(flash[:danger]).to eq("Partners must have an address or a service area inside your neighbourhood")
        expect(partner.service_areas.reload.map(&:neighbourhood_id)).to contain_exactly(ward.id, outside_ward.id)
      end
    end
  end

  describe "POST /admin/partners" do
    context "as a neighbourhood admin" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

      before { sign_in user }

      # Regression test for issue #3356: the wizard submits a blank
      # neighbourhood_id for any untouched "New Service Area" picker row
      it "creates a partner despite a leftover blank service area row" do
        post admin_partners_url(host: admin_host), params: {
          partner: {
            name: "Common Arts",
            service_areas_attributes: {
              "0" => { neighbourhood_id: ward.id.to_s, _destroy: "false" },
              "1" => { neighbourhood_id: "", _destroy: "false" }
            }
          }
        }

        partner = Partner.find_by(name: "Common Arts")
        expect(partner).to be_present
        expect(partner.service_areas.map(&:neighbourhood_id)).to eq([ward.id])
        expect(response).to be_redirect
      end

      # Regression test for issue #3356: service areas rendered as cards after a
      # failed save must round-trip their neighbourhood_id, or they are silently
      # dropped from the retry submission
      it "keeps service areas submittable when validation fails and the form re-renders" do
        post admin_partners_url(host: admin_host), params: {
          partner: {
            name: "",
            service_areas_attributes: {
              "0" => { neighbourhood_id: ward.id.to_s }
            }
          }
        }

        expect(response).to have_http_status(:unprocessable_content)

        doc = Nokogiri::HTML(response.body)
        neighbourhood_inputs = doc.css("input[name^='partner[service_areas_attributes]']")
                                  .select { |input| input["name"].end_with?("[neighbourhood_id]") }
                                  .map { |input| input["value"] }
        expect(neighbourhood_inputs).to include(ward.id.to_s)
      end
    end
  end
end
