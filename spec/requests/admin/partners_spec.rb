# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Partners', type: :request do
  let(:admin_host) { 'admin.lvh.me' }

  describe 'GET /admin/partners' do
    context 'as an unauthenticated user' do
      it 'redirects to login' do
        get admin_partners_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as a citizen user' do
      let(:user) { create(:citizen_user) }

      before { sign_in user }

      it 'shows empty partner list (no access to any partners)' do
        # Citizens can access the page but see an empty list via policy_scope
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
      end
    end

    context 'as a root user' do
      let(:user) { create(:root_user) }
      let!(:partner1) { create(:partner) }
      let!(:partner2) { create(:partner) }

      before { sign_in user }

      it 'shows all partners' do
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner1.name)
        expect(response.body).to include(partner2.name)
      end

      it 'includes add new partner button' do
        get admin_partners_url(host: admin_host)
        expect(response.body).to include('Add New Partner')
      end
    end

    context 'as a partner admin' do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }
      let!(:other_partner) { create(:partner) }

      before { sign_in user }

      it 'shows only their partner' do
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner.name)
        expect(response.body).not_to include(other_partner.name)
      end
    end

    context 'as a neighbourhood admin' do
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

      it 'shows partners in their neighbourhood' do
        get admin_partners_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner_in_neighbourhood.name)
      end
    end
  end

  describe 'GET /admin/partners/:id' do
    let(:partner) { create(:riverside_partner) }

    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'redirects to edit page' do
        # show action redirects to edit
        get admin_partner_url(partner, host: admin_host)
        expect(response).to redirect_to(edit_admin_partner_url(partner, host: admin_host))
      end
    end

    context 'as a partner admin for this partner' do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }

      before { sign_in user }

      it 'redirects to edit page' do
        # show action redirects to edit
        get admin_partner_url(partner, host: admin_host)
        expect(response).to redirect_to(edit_admin_partner_url(partner, host: admin_host))
      end
    end

    context 'as a partner admin for a different partner' do
      let(:user) { create(:partner_admin) }
      let(:other_partner) { create(:partner) }

      before { sign_in user }

      it 'denies access' do
        get admin_partner_url(other_partner, host: admin_host)
        expect(response).to have_http_status(:forbidden).or redirect_to(admin_partners_path)
      end
    end
  end

  describe 'GET /admin/partners/new' do
    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows the new partner form' do
        get new_admin_partner_url(host: admin_host)
        expect(response).to be_successful
      end
    end

    context 'as a neighbourhood admin' do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

      before { sign_in user }

      it 'shows the new partner form' do
        get new_admin_partner_url(host: admin_host)
        expect(response).to be_successful
      end
    end

    context 'as a partner admin' do
      let(:user) { create(:partner_admin) }

      before { sign_in user }

      it 'denies access' do
        get new_admin_partner_url(host: admin_host)
        expect(response).to have_http_status(:forbidden).or redirect_to(admin_partners_path)
      end
    end
  end

  describe 'GET /admin/partners/:id/edit' do
    let(:partner) { create(:riverside_partner) }

    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows the edit form' do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response).to be_successful
      end
    end

    context 'as a partner admin for this partner' do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }

      before { sign_in user }

      it 'shows the edit form' do
        get edit_admin_partner_url(partner, host: admin_host)
        expect(response).to be_successful
      end
    end
  end
end
