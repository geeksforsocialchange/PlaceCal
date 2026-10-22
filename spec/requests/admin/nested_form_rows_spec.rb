# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin nested form rows", type: :request do
  let(:areas) { create_list(:neighbourhood, 5) }
  let(:new_index) { "1761134400000" }

  def template_html(wrapper_class)
    Nokogiri::HTML(response.body).at_css(".#{wrapper_class} template").inner_html
  end

  before { sign_in create(:root_user) }

  describe "partner service areas" do
    let(:partner) { create(:riverside_partner) }

    it "renders existing rows and a new-row template, then keeps, removes and adds rows" do
      kept = partner.service_areas.create!(neighbourhood: areas[0])
      removed = partner.service_areas.create!(neighbourhood: areas[1])

      get edit_admin_partner_url(partner, host: admin_host)
      expect(template_html("nested-form-service-areas"))
        .to include('name="partner[service_areas_attributes][NEW_RECORD][neighbourhood_id]"')
      expect(response.body).to include('name="partner[service_areas_attributes][1][id]"')
      expect(response.body).to include('name="partner[service_areas_attributes][1][_destroy]"')

      put admin_partner_url(partner, host: admin_host), params: {
        partner: {
          name: partner.name,
          service_areas_attributes: {
            "0" => { id: kept.id, neighbourhood_id: areas[0].id, _destroy: "false" },
            "1" => { id: removed.id, neighbourhood_id: areas[1].id, _destroy: "1" },
            new_index => { neighbourhood_id: areas[2].id, _destroy: "false" }
          }
        }
      }

      expect(response).to redirect_to(edit_admin_partner_url(partner, host: admin_host))
      expect(partner.service_areas.reload.map(&:neighbourhood_id)).to contain_exactly(areas[0].id, areas[2].id)
    end

    it "renders the new-row template on the new partner wizard" do
      get new_admin_partner_url(host: admin_host)

      expect(template_html("nested-form-service-areas"))
        .to include('name="partner[service_areas_attributes][NEW_RECORD][neighbourhood_id]"')
    end
  end

  describe "site secondary neighbourhoods" do
    let(:site) { create(:site) }

    it "renders existing rows and a new-row template, then keeps, removes and adds rows" do
      site.sites_neighbourhoods.create!(neighbourhood: areas[0], relation_type: "Primary")
      kept = site.sites_neighbourhoods.create!(neighbourhood: areas[1], relation_type: "Secondary")
      removed = site.sites_neighbourhoods.create!(neighbourhood: areas[2], relation_type: "Secondary")

      get edit_admin_site_url(site, host: admin_host)
      expect(template_html("nested-form-sites-neighbourhoods"))
        .to include('name="site[sites_neighbourhoods_attributes][NEW_RECORD][neighbourhood_id]"')
      expect(response.body).to include('name="site[sites_neighbourhoods_attributes][2][id]"')
      expect(response.body).to include('name="site[sites_neighbourhoods_attributes][2][_destroy]"')

      put admin_site_url(site, host: admin_host), params: {
        site: {
          sites_neighbourhoods_attributes: {
            "1" => { id: kept.id, neighbourhood_id: areas[1].id, relation_type: "Secondary", _destroy: "false" },
            "2" => { id: removed.id, neighbourhood_id: areas[2].id, relation_type: "Secondary", _destroy: "1" },
            new_index => { neighbourhood_id: areas[3].id, relation_type: "Secondary", _destroy: "false" }
          }
        }
      }

      expect(response).to redirect_to(edit_admin_site_url(site, host: admin_host))
      expect(site.sites_neighbourhoods.reload.map { |sn| [sn.neighbourhood_id, sn.relation_type] })
        .to contain_exactly([areas[0].id, "Primary"], [areas[1].id, "Secondary"], [areas[3].id, "Secondary"])
    end
  end

  describe "user neighbourhoods" do
    let(:user) { create(:user) }
    let!(:kept) { user.neighbourhoods_users.create!(neighbourhood: areas[0]) }
    let!(:edited) { user.neighbourhoods_users.create!(neighbourhood: areas[1]) }
    let!(:removed) { user.neighbourhoods_users.create!(neighbourhood: areas[2]) }

    it "renders existing rows and a new-row template, then keeps, edits, removes and adds rows" do
      get edit_admin_user_url(user, host: admin_host)
      expect(template_html("nested-form-neighbourhoods-users"))
        .to include('name="user[neighbourhoods_users_attributes][NEW_RECORD][neighbourhood_id]"')
      expect(response.body).to include('name="user[neighbourhoods_users_attributes][2][id]"')
      expect(response.body).to include('name="user[neighbourhoods_users_attributes][2][_destroy]"')

      put admin_user_url(user, host: admin_host), params: {
        user: {
          neighbourhoods_users_attributes: {
            "0" => { id: kept.id, neighbourhood_id: areas[0].id, _destroy: "false" },
            "1" => { id: edited.id, neighbourhood_id: areas[3].id, _destroy: "false" },
            "2" => { id: removed.id, neighbourhood_id: areas[2].id, _destroy: "1" },
            new_index => { neighbourhood_id: areas[4].id, _destroy: "false" }
          }
        }
      }

      expect(response).to redirect_to(edit_admin_user_url(user, host: admin_host))
      expect(user.neighbourhoods.reload.ids).to contain_exactly(areas[0].id, areas[3].id, areas[4].id)
    end

    it "keeps existing and added rows when validation fails and the form re-renders" do
      put admin_user_url(user, host: admin_host), params: {
        user: {
          email: "",
          neighbourhoods_users_attributes: { new_index => { neighbourhood_id: areas[4].id, _destroy: "false" } }
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      neighbourhood_ids = Nokogiri::HTML(response.body)
                                  .css("input[name^='user[neighbourhoods_users_attributes]'][name$='[neighbourhood_id]']")
                                  .map { |input| input["value"] }
      expect(neighbourhood_ids).to include(areas[0].id.to_s, areas[4].id.to_s)
    end

    it "renders the new-row template on the new user form" do
      get new_admin_user_url(host: admin_host)

      expect(template_html("nested-form-neighbourhoods-users"))
        .to include('name="user[neighbourhoods_users_attributes][NEW_RECORD][neighbourhood_id]"')
    end
  end
end
