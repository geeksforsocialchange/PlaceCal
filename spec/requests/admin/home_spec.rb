# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Home', type: :request do
  let(:admin_host) { 'admin.lvh.me' }

  let!(:root_user) { create(:root_user) }
  let!(:citizen_user) { create(:citizen_user) }
  let!(:site_admin) { create(:user, role: 'root') }
  let!(:site) { create(:site) }
  let!(:site_admin_site) { create(:site, name: 'Site Admin Site', site_admin: site_admin) }

  describe 'GET /admin (dashboard)' do
    context 'without authentication' do
      before { create_default_site }

      it 'redirects to login page' do
        get "http://#{admin_host}"
        expect(response).to redirect_to("http://#{admin_host}/users/sign_in")
      end
    end

    context 'as a root user' do
      before { sign_in root_user }

      it 'shows dashboard with correct title' do
        get "http://#{admin_host}"
        expect(response).to be_successful
        expect(response.body).to include('<title>Dashboard | PlaceCal Admin</title>')
      end

      it 'shows all sites when no sites assigned' do
        get "http://#{admin_host}"
        expect(response).to be_successful
        expect(response.body).to include(site.name)
        expect(response.body).to include(site_admin_site.name)
      end
    end

    context 'as a site admin' do
      before { sign_in site_admin }

      it 'shows only assigned sites' do
        get "http://#{admin_host}"
        expect(response).to be_successful
        expect(response.body).to include(site_admin_site.name)
        expect(response.body).not_to include(">#{site.name}<")
      end
    end

    context 'as a citizen with no permissions' do
      before { sign_in citizen_user }

      it 'shows missing permissions warning' do
        get "http://#{admin_host}"
        expect(response).to be_successful
        expect(response.body).to include('<title>Dashboard | PlaceCal Admin</title>')
        expect(response.body).to include('Missing Permissions')
      end
    end
  end
end
