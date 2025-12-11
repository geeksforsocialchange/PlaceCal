# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Users', type: :request do
  describe 'GET /admin/users' do
    context 'as an unauthenticated user' do
      it 'redirects to login' do
        get admin_users_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as a citizen user' do
      let(:user) { create(:citizen_user) }

      before { sign_in user }

      it 'denies access' do
        get admin_users_url(host: admin_host)
        expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
      end
    end

    context 'as a root user' do
      let(:user) { create(:root_user) }
      let!(:users) { create_list(:user, 3) }

      before { sign_in user }

      it 'shows all users' do
        get admin_users_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end

  describe 'GET /admin/users/:id/edit' do
    let(:target_user) { create(:user) }

    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows user edit form' do
        # NOTE: users controller only has edit, not show
        get edit_admin_user_url(target_user, host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(target_user.email)
      end
    end
  end

  describe 'GET /admin/users/new' do
    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows new user form with correct title' do
        get new_admin_user_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include('<title>New User | PlaceCal Admin</title>')
      end

      it 'shows form fields for user creation' do
        get new_admin_user_url(host: admin_host)
        expect(response.body).to include('First name')
        expect(response.body).to include('Last name')
        expect(response.body).to include('Email')
        expect(response.body).to include('Phone')
        expect(response.body).to include('Partners')
        expect(response.body).to include('Neighbourhoods')
        expect(response.body).to include('Role')
      end

      it 'preselects partner when partner_id provided' do
        partner = create(:partner)
        user.partners << partner
        get new_admin_user_url(host: admin_host, params: { partner_id: partner.id })
        expect(response).to be_successful
        expect(response.body).to include('selected')
      end
    end

    context 'as a neighbourhood admin with no partners' do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

      before { sign_in user }

      it 'shows form with empty partner selector' do
        get new_admin_user_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end

  describe 'GET /admin/users index content' do
    let(:user) { create(:root_user) }

    before { sign_in user }

    it 'shows correct title and heading' do
      get admin_users_url(host: admin_host)
      expect(response.body).to include('<title>Users | PlaceCal Admin</title>')
      expect(response.body).to include('Users')
    end
  end

  describe 'GET /admin/profile' do
    context 'as a root user' do
      let(:user) { create(:root_user) }
      let(:partner) { create(:partner) }
      let(:ward) { create(:riverside_ward) }

      before do
        user.partners << partner
        user.neighbourhoods << ward
        sign_in user
      end

      it 'shows profile page' do
        get admin_profile_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include('Edit Profile')
      end

      it 'shows basic information section' do
        get admin_profile_url(host: admin_host)
        expect(response.body).to include('Basic information')
        expect(response.body).to include('First name')
        expect(response.body).to include('Last name')
        expect(response.body).to include('Email')
      end

      it 'shows password section' do
        get admin_profile_url(host: admin_host)
        expect(response.body).to include('Password')
      end

      it 'shows admin rights section' do
        get admin_profile_url(host: admin_host)
        expect(response.body).to include('Admin rights')
        expect(response.body).to include(partner.name)
      end
    end

    context 'as a citizen with no permissions' do
      let(:user) { create(:citizen_user) }

      before { sign_in user }

      it 'shows no admin rights warning' do
        get admin_profile_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include('no-admin-rights')
      end
    end
  end

  describe 'POST /admin/users' do
    context 'with bad avatar upload' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows error for invalid avatar type' do
        new_user_params = {
          email: 'user@example.com',
          role: 'root',
          avatar: fixture_file_upload('bad-cat-picture.bmp')
        }

        post admin_users_url(host: admin_host), params: { user: new_user_params }

        expect(response).not_to be_redirect
        expect(response.body).to include('error prohibited this User from being saved')
        expect(response.body).to include('Avatar')
        expect(response.body).to include('not allowed to upload')
        expect(response.body).to include('bmp')
      end
    end

    context 'as a neighbourhood admin' do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let(:partner) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end

      before { sign_in user }

      it 'can create user with partner' do
        new_user_params = {
          email: 'newuser@example.com',
          partner_ids: [partner.id]
        }

        post admin_users_url(host: admin_host), params: { user: new_user_params }
        expect(response).to be_redirect
      end

      it 'cannot create user without partner' do
        new_user_params = {
          email: 'newuser@example.com',
          partner_ids: ['']
        }

        post admin_users_url(host: admin_host), params: { user: new_user_params }
        expect(response).not_to be_redirect
      end
    end

    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'can create user without partner' do
        new_user_params = {
          email: 'newuser@example.com',
          partner_ids: ['']
        }

        post admin_users_url(host: admin_host), params: { user: new_user_params }
        expect(response).to be_redirect
      end
    end
  end

  describe 'PUT /admin/users/:id' do
    let(:user) { create(:root_user) }
    let(:target_user) { create(:user) }

    before { sign_in user }

    it 'shows error for invalid avatar type' do
      user_params = {
        email: target_user.email,
        avatar: fixture_file_upload('bad-cat-picture.bmp')
      }

      put admin_user_url(target_user, host: admin_host), params: { user: user_params }

      expect(response).not_to be_redirect
      expect(response.body).to include('error prohibited this User from being saved')
      expect(response.body).to include('Avatar')
      expect(response.body).to include('not allowed to upload')
    end
  end
end
