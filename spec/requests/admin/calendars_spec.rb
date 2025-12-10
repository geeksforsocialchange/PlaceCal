# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Calendars', type: :request do
  let(:admin_host) { 'admin.lvh.me' }
  let(:partner) { create(:partner) }

  describe 'GET /admin/calendars' do
    context 'as an unauthenticated user' do
      it 'redirects to login' do
        get admin_calendars_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as a root user' do
      let(:user) { create(:root_user) }
      let!(:calendars) do
        Array.new(3) do
          cal = build(:calendar, partner: partner)
          allow(cal).to receive(:check_source_reachable)
          cal.save!
          cal
        end
      end

      before { sign_in user }

      it 'shows all calendars' do
        get admin_calendars_url(host: admin_host)
        expect(response).to be_successful
        calendars.each do |calendar|
          expect(response.body).to include(calendar.name)
        end
      end
    end

    context 'as a partner admin' do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }
      let!(:partner_calendar) do
        cal = build(:calendar, partner: partner)
        allow(cal).to receive(:check_source_reachable)
        cal.save!
        cal
      end
      let!(:other_calendar) do
        other_partner = create(:partner)
        cal = build(:calendar, partner: other_partner)
        allow(cal).to receive(:check_source_reachable)
        cal.save!
        cal
      end

      before { sign_in user }

      it 'shows only their calendars' do
        get admin_calendars_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner_calendar.name)
        expect(response.body).not_to include(other_calendar.name)
      end
    end
  end

  describe 'GET /admin/calendars/:id' do
    let(:calendar) do
      cal = build(:calendar, partner: partner)
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end

    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows the calendar details' do
        get admin_calendar_url(calendar, host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(calendar.name)
      end
    end
  end

  describe 'GET /admin/calendars/new' do
    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows the new calendar form' do
        get new_admin_calendar_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end
end
