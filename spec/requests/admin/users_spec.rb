# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Users', type: :request do
  let(:admin_host) { 'admin.lvh.me' }

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
        # Note: users controller only has edit, not show
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

      it 'shows new user form' do
        get new_admin_user_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end
end
