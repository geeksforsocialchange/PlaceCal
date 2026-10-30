# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sites", type: :request do
  let!(:root_user) { create(:root_user) }
  let!(:another_root) { create(:user, role: "root") }
  let!(:site_admin_user) { create(:user, role: "root") }
  let!(:site) { create(:site, site_admin: site_admin_user) }
  let!(:another_site) { create(:site, name: "another", site_admin: another_root) }
  let(:site_admin) { site.site_admin }
  let!(:neighbourhoods) { create_list(:neighbourhood, 5) }
  let!(:category_tag) { create(:tag, type: "Category") }
  let!(:partnership_tag) { create(:partnership) }

  describe "GET /admin/sites" do
    context "as a root user" do
      before { sign_in root_user }

      it "has appropriate title and heading" do
        get admin_sites_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("<title>Sites | PlaceCal Admin</title>")
        expect(response.body).to include("<h1")
        expect(response.body).to include("Sites")
      end

      it "loads the sites page successfully" do
        get admin_sites_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("Sites")
      end
    end
  end

  describe "GET /admin/sites/new" do
    context "as a root user" do
      before { sign_in root_user }

      it "has appropriate title" do
        get new_admin_site_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("<title>New Site | PlaceCal Admin</title>")
      end

      it "tells the user the slug auto-generates from the name when left blank" do
        get new_admin_site_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("Leave blank to auto-generate from name")
      end
    end
  end

  describe "GET /admin/sites/:id/edit" do
    context "as a root user" do
      before { sign_in root_user }

      it "shows all form fields" do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful

        # Basic fields
        expect(response.body).to include("Name")
        expect(response.body).to include("Place Name")
        expect(response.body).to include("Tagline")
        expect(response.body).to include("Domain")
        expect(response.body).to include("Slug")
        expect(response.body).to include("Description")
        expect(response.body).to include("Site Admin")

        # Image fields
        expect(response.body).to include("Theme")
        expect(response.body).to include("Logo")
        expect(response.body).to include("Footer Logo")
        expect(response.body).to include("Hero Image")
        expect(response.body).to include("Image Credit")
      end

      it "shows cascading neighbourhood selectors for secondary neighbourhoods" do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful

        # The nested-form template now uses cascading neighbourhood component
        # with region/area/ward dropdowns loaded via Stimulus
        nested_form_template = response.body.match(%r{<template data-nested-form-target="template">(.*?)</template>}m)
        expect(nested_form_template).to be_present

        template_content = CGI.unescape_html(nested_form_template[1])
        expect(template_content).to include("data-controller=\"cascading-neighbourhood\"")
        expect(template_content).to include("data-cascading-neighbourhood-target=\"region\"")
        expect(template_content).to include("data-cascading-neighbourhood-target=\"district\"")
        expect(template_content).to include("data-cascading-neighbourhood-target=\"ward\"")
      end
    end

    context "as a site admin" do
      before do
        site_admin.neighbourhoods << neighbourhoods.first
        site_admin.neighbourhoods << neighbourhoods.second
        sign_in site_admin
      end

      it "shows appropriate fields but not admin-only fields" do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful

        # Basic fields visible
        expect(response.body).to include("Name")
        expect(response.body).to include("Place Name")
        expect(response.body).to include("Tagline")
        expect(response.body).to include("Slug")
        expect(response.body).to include("Description")

        # Image fields visible
        expect(response.body).to include("Theme")
        expect(response.body).to include("Logo")
        expect(response.body).to include("Footer Logo")
        expect(response.body).to include("Hero Image")
        expect(response.body).to include("Image Credit")
      end
    end

    context "with partnership tags" do
      before do
        site.tags << partnership_tag
        site_admin.tags << partnership_tag
        sign_in site_admin
      end

      it "shows site tags in the partnerships tab" do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful
        # Tags are displayed by name in the select, not with their type prefix
        expect(response.body).to include(partnership_tag.name)
        expect(response.body).to include("Partnership Tags")
      end
    end
  end

  describe "domain field" do
    before do
      serve_hosts("placecal.org", "*.placecal.org", "transdimension.uk")
      sign_in root_user
    end

    it "explains what a blank domain means for this site" do
      get edit_admin_site_url(site, host: admin_host)
      expect(response.body).to include("Leave blank to use #{site.slug}.placecal.org")
    end

    it "says when the domain is served by PlaceCal" do
      site.update!(domain: "transdimension.uk")
      get edit_admin_site_url(site, host: admin_host)
      expect(response.body).to include("Served by PlaceCal at transdimension.uk.")
    end

    it "says when the domain is an external website" do
      site.update!(domain: "fruitsaladevents.co.uk")
      get edit_admin_site_url(site, host: admin_host)
      expect(response.body).to include("External website: fruitsaladevents.co.uk.")
    end

    it "saves a pasted URL as a bare domain" do
      put admin_site_url(site, host: admin_host), params: { site: { domain: "https://Example.org/" } }
      expect(site.reload.domain).to eq("example.org")
    end
  end

  describe "POST /admin/sites" do
    context "with a blank slug" do
      before { sign_in root_user }

      it "auto-generates the slug from the name" do
        new_site_params = {
          name: "My Brand New Site",
          slug: ""
        }

        expect do
          post admin_sites_url(host: admin_host), params: { site: new_site_params }
        end.to change(Site, :count).by(1)

        expect(Site.last.slug).to eq("my-brand-new-site")
      end
    end

    context "with bad image uploads" do
      before { sign_in root_user }

      it "shows errors for invalid image types" do
        new_site_params = {
          name: "a new site",
          slug: "a-slug",
          logo: fixture_file_upload("bad-cat-picture.bmp"),
          footer_logo: fixture_file_upload("bad-cat-picture.bmp"),
          hero_image: fixture_file_upload("bad-cat-picture.bmp")
        }

        post admin_sites_url(host: admin_host), params: { site: new_site_params }

        expect(response).not_to be_redirect
        expect(response.body).to include("errors prohibited this Site from being saved")

        # Form error messages
        expect(response.body).to include("Logo")
        expect(response.body).to include("Footer Logo")
        expect(response.body).to include("Hero Image")
        expect(response.body).to include("not allowed to upload")
        expect(response.body).to include("bmp")
      end
    end
  end

  describe "PUT /admin/sites/:id" do
    context "when a newly added neighbourhood fails validation and the form re-renders" do
      before { sign_in root_user }

      # Regression test for the same class of bug as #3356: a just-added secondary
      # neighbourhood re-renders as a NeighbourhoodCard, which must emit a hidden
      # neighbourhood_id or the row is silently dropped from the retry submission.
      it "keeps the added neighbourhood submittable" do
        ward = neighbourhoods.first

        put admin_site_url(site, host: admin_host), params: {
          site: {
            name: "", # forces a validation failure so the form re-renders
            sites_neighbourhoods_attributes: {
              "0" => { neighbourhood_id: ward.id.to_s, relation_type: "Secondary" }
            }
          }
        }

        expect(response).to have_http_status(:unprocessable_content)

        doc = Nokogiri::HTML(response.body)
        neighbourhood_ids = doc.css("input[name^='site[sites_neighbourhoods_attributes]']")
                               .select { |input| input["name"].end_with?("[neighbourhood_id]") }
                               .map { |input| input["value"] }
        expect(neighbourhood_ids).to include(ward.id.to_s)
      end
    end

    context "when a secondary neighbourhood row is older than the primary" do
      before { sign_in root_user }

      it "saves what the edit form submits" do
        secondary = create(:sites_neighbourhood, site:, neighbourhood: neighbourhoods.first, relation_type: "Secondary")
        primary = create(:sites_neighbourhood, site:, neighbourhood: neighbourhoods.second, relation_type: "Primary")

        get edit_admin_site_url(site, host: admin_host)
        form = Nokogiri::HTML(response.body).css("form").find { |f| f.at_css("input[name^='site[sites_neighbourhood']") }
        fields = form.css("input[name^='site[sites_neighbourhood']").reject { |input| input.ancestors("template").any? }
        params = Rack::Utils.parse_nested_query(fields.map { |input| "#{CGI.escape(input['name'])}=#{CGI.escape(input['value'].to_s)}" }.join("&"))
        params["site"]["name"] = "Renamed site"

        put(admin_site_url(site, host: admin_host), params:)

        expect(response).to redirect_to(edit_admin_site_url(site, host: admin_host))
        expect(site.reload.name).to eq("Renamed site")
        expect(site.sites_neighbourhood).to eq(primary)
        expect(site.sites_neighbourhoods.find(secondary.id).relation_type).to eq("Secondary")
      end
    end

    context "with bad image uploads" do
      before { sign_in root_user }

      it "shows errors for invalid image types" do
        site_params = {
          name: "updated site",
          slug: "a-slug",
          logo: fixture_file_upload("bad-cat-picture.bmp"),
          footer_logo: fixture_file_upload("bad-cat-picture.bmp"),
          hero_image: fixture_file_upload("bad-cat-picture.bmp")
        }

        put admin_site_url(site, host: admin_host), params: { site: site_params }

        expect(response).not_to be_redirect
        expect(response.body).to include("errors prohibited this Site from being saved")

        # Form error messages
        expect(response.body).to include("Logo")
        expect(response.body).to include("Footer Logo")
        expect(response.body).to include("Hero Image")
        expect(response.body).to include("not allowed to upload")
        expect(response.body).to include("bmp")
      end
    end
  end
end

# Extension themes swap in an engine's views and copy, and only exist on
# installations that ship that gem, so they are root's to set (#3368, WP 4.5).
# Site admins keep the core themes and the fields they already had.
RSpec.describe "Admin::Sites theme and contact authorisation", type: :request do
  let!(:themed_site) { create(:site, slug: "themed-site", theme: "pink", site_admin:) }
  let(:site_admin) { create(:citizen_user) }
  let(:root_user) { create(:root_user) }

  def put_site(attributes)
    put admin_site_url(themed_site, host: admin_host), params: { site: attributes }
  end

  context "as a site admin" do
    before { sign_in site_admin }

    it "cannot move the site onto an extension theme" do
      put_site(theme: "example_theme")

      expect(response).to redirect_to(admin_root_path)
      expect(themed_site.reload.theme).to eq("pink")
    end

    it "can still pick a core theme" do
      put_site(theme: "blue")

      expect(themed_site.reload.theme).to eq("blue")
    end

    # Blanking is how a forged param takes a site off its theme without naming
    # another one: the row saves (Site validates theme only on change, with
    # allow_blank) and the site renders with no stylesheet at all.
    it "cannot strip the theme with a blank" do
      put_site(theme: "")

      expect(response).to redirect_to(admin_root_path)
      expect(themed_site.reload.theme).to eq("pink")
    end

    it "is offered core themes only in the theme select" do
      get edit_admin_site_url(themed_site, host: admin_host)

      options = Nokogiri::HTML(response.body).css("select#site_theme option").map { |o| o["value"] }
      expect(options).to include("pink", "blue")
      expect(options).not_to include("example_theme")
      expect(options).not_to include("")
    end

    it "can set the site's contact email" do
      put_site(contact_email: "hello@example.org")

      expect(themed_site.reload.contact_email).to eq("hello@example.org")
    end
  end

  context "as a root user" do
    before { sign_in root_user }

    it "can move the site onto an extension theme" do
      put_site(theme: "example_theme")

      expect(themed_site.reload.theme).to eq("example_theme")
    end

    it "is offered extension themes in the theme select" do
      get edit_admin_site_url(themed_site, host: admin_host)

      options = Nokogiri::HTML(response.body).css("select#site_theme option").map { |o| o["value"] }
      expect(options).to include("example_theme")
    end
  end

  context "as a citizen who administers nothing" do
    before { sign_in create(:citizen_user) }

    it "cannot set the site's contact email" do
      put_site(contact_email: "hello@example.org")

      expect(response).to redirect_to(admin_root_path)
      expect(themed_site.reload.contact_email).to be_blank
    end
  end
end

RSpec.describe "Admin::Sites neighbourhood authorisation", type: :request do
  let(:site_admin) { create(:citizen_user) }
  let!(:site) { create(:site, name: "Original name", site_admin:) }
  let(:areas) { create_list(:neighbourhood, 4) }
  let!(:primary) { create(:sites_neighbourhood, site:, neighbourhood: areas[0], relation_type: "Primary") }
  let!(:secondary) { create(:sites_neighbourhood, site:, neighbourhood: areas[1], relation_type: "Secondary") }
  let(:row_changes) do
    {
      name: "New name",
      sites_neighbourhoods_attributes: {
        "0" => { id: secondary.id, neighbourhood_id: areas[1].id, relation_type: "Secondary", _destroy: "1" },
        "1" => { neighbourhood_id: areas[2].id, relation_type: "Secondary", _destroy: "false" }
      }
    }
  end

  def put_site(attributes)
    put admin_site_url(site, host: admin_host), params: { site: attributes }
  end

  def neighbourhood_rows
    site.sites_neighbourhoods.reload.map { |sn| [sn.neighbourhood_id, sn.relation_type] }
  end

  context "as the site's admin" do
    before { sign_in site_admin }

    it "saves their other edits but leaves the neighbourhoods unchanged" do
      put_site(row_changes)

      expect(response).to redirect_to(edit_admin_site_url(site, host: admin_host))
      expect(site.reload.name).to eq("New name")
      expect(neighbourhood_rows).to contain_exactly([areas[0].id, "Primary"], [areas[1].id, "Secondary"])
    end

    it "cannot change the primary neighbourhood" do
      put_site(name: "New name",
               sites_neighbourhood_attributes: { id: primary.id, neighbourhood_id: areas[3].id, relation_type: "Primary" })

      expect(site.reload.name).to eq("New name")
      expect(site.primary_neighbourhood).to eq(areas[0])
    end
  end

  context "as a root user" do
    before { sign_in create(:root_user) }

    it "can add and remove neighbourhoods" do
      put_site(row_changes)

      expect(response).to redirect_to(edit_admin_site_url(site, host: admin_host))
      expect(site.reload.name).to eq("New name")
      expect(neighbourhood_rows).to contain_exactly([areas[0].id, "Primary"], [areas[2].id, "Secondary"])
    end
  end
end
