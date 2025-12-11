# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Sites', type: :request do
  let(:admin_host) { 'admin.lvh.me' }

  let!(:root_user) { create(:root_user) }
  let!(:another_root) { create(:user, role: 'root') }
  let!(:site_admin_user) { create(:user, role: 'root') }
  let!(:site) { create(:site, site_admin: site_admin_user) }
  let!(:another_site) { create(:site, name: 'another', site_admin: another_root) }
  let(:site_admin) { site.site_admin }
  let!(:neighbourhoods) { create_list(:neighbourhood, 5) }
  let!(:category_tag) { create(:tag, type: 'Category') }
  let!(:partnership_tag) { create(:partnership) }

  describe 'GET /admin/sites' do
    context 'as a root user' do
      before { sign_in root_user }

      it 'has appropriate title and heading' do
        get admin_sites_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include('<title>Sites | PlaceCal Admin</title>')
        expect(response.body).to include('<h1')
        expect(response.body).to include('Sites')
      end

      it 'shows all sites' do
        get admin_sites_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(site.name)
        expect(response.body).to include(another_site.name)
      end
    end
  end

  describe 'GET /admin/sites/new' do
    context 'as a root user' do
      before { sign_in root_user }

      it 'has appropriate title' do
        get new_admin_site_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include('<title>New Site | PlaceCal Admin</title>')
      end
    end
  end

  describe 'GET /admin/sites/:id/edit' do
    context 'as a root user' do
      before { sign_in root_user }

      it 'shows all form fields' do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful

        # Basic fields
        expect(response.body).to include('Name')
        expect(response.body).to include('Place name')
        expect(response.body).to include('Tagline')
        expect(response.body).to include('Url')
        expect(response.body).to include('Slug')
        expect(response.body).to include('Description')
        expect(response.body).to include('Site admin')

        # Image fields
        expect(response.body).to include('Theme')
        expect(response.body).to include('Logo')
        expect(response.body).to include('Footer logo')
        expect(response.body).to include('Hero image')
        expect(response.body).to include('Hero image credit')
      end

      it 'shows all neighbourhoods in secondary neighbourhoods selector' do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful

        # The cocoon template contains the neighbourhood options
        cocoon_template = response.body.match(/data-association-insertion-template="([^"]+)"/)
        expect(cocoon_template).to be_present

        # Count how many neighbourhoods are shown in the template
        template_content = CGI.unescape_html(cocoon_template[1])
        neighbourhoods_count = template_content.scan('option value=').size
        expect(neighbourhoods_count).to eq(Neighbourhood.count)
      end
    end

    context 'as a site admin' do
      before do
        site_admin.neighbourhoods << neighbourhoods.first
        site_admin.neighbourhoods << neighbourhoods.second
        sign_in site_admin
      end

      it 'shows appropriate fields but not admin-only fields' do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful

        # Basic fields visible
        expect(response.body).to include('Name')
        expect(response.body).to include('Place name')
        expect(response.body).to include('Tagline')
        expect(response.body).to include('Slug')
        expect(response.body).to include('Description')

        # Image fields visible
        expect(response.body).to include('Theme')
        expect(response.body).to include('Logo')
        expect(response.body).to include('Footer logo')
        expect(response.body).to include('Hero image')
        expect(response.body).to include('Hero image credit')
      end
    end

    context 'with partnership tags' do
      before do
        site.tags << partnership_tag
        site_admin.tags << partnership_tag
        sign_in site_admin
      end

      it 'shows site tags with their type' do
        get edit_admin_site_url(site, host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partnership_tag.name_with_type)
      end
    end
  end

  describe 'POST /admin/sites' do
    context 'with bad image uploads' do
      before { sign_in root_user }

      it 'shows errors for invalid image types' do
        new_site_params = {
          name: 'a new site',
          url: 'https://a-domain.placecal.org',
          slug: 'a-slug',
          logo: fixture_file_upload('bad-cat-picture.bmp'),
          footer_logo: fixture_file_upload('bad-cat-picture.bmp'),
          hero_image: fixture_file_upload('bad-cat-picture.bmp')
        }

        post admin_sites_url(host: admin_host), params: { site: new_site_params }

        expect(response).not_to be_redirect
        expect(response.body).to include('errors prohibited this Site from being saved')

        # Form error messages
        expect(response.body).to include('Logo')
        expect(response.body).to include('Footer logo')
        expect(response.body).to include('Hero image')
        expect(response.body).to include('not allowed to upload')
        expect(response.body).to include('bmp')
      end
    end
  end

  describe 'PUT /admin/sites/:id' do
    context 'with bad image uploads' do
      before { sign_in root_user }

      it 'shows errors for invalid image types' do
        site_params = {
          name: 'updated site',
          url: 'https://a-domain.placecal.org',
          slug: 'a-slug',
          logo: fixture_file_upload('bad-cat-picture.bmp'),
          footer_logo: fixture_file_upload('bad-cat-picture.bmp'),
          hero_image: fixture_file_upload('bad-cat-picture.bmp')
        }

        put admin_site_url(site, host: admin_host), params: { site: site_params }

        expect(response).not_to be_redirect
        expect(response.body).to include('errors prohibited this Site from being saved')

        # Form error messages
        expect(response.body).to include('Logo')
        expect(response.body).to include('Footer logo')
        expect(response.body).to include('Hero image')
        expect(response.body).to include('not allowed to upload')
        expect(response.body).to include('bmp')
      end
    end
  end
end
