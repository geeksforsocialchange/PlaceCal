# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Calendars', type: :request do
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
    let!(:partner1) { create(:partner) }
    let!(:partner2) { create(:partner) }

    context 'as a root user' do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it 'shows the new calendar form with correct title' do
        get new_admin_calendar_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include('<title>New Calendar | PlaceCal Admin</title>')
      end

      it 'shows all partners in selector' do
        get new_admin_calendar_url(host: admin_host)
        expect(response.body).to include(partner1.name)
        expect(response.body).to include(partner2.name)
      end

      it 'preselects partner when partner_id provided' do
        user.partners << partner1
        get new_admin_calendar_url(host: admin_host, params: { partner_id: partner1.id })
        expect(response).to be_successful
        expect(response.body).to include('selected')
      end
    end

    context 'as a partner admin' do
      let(:user) { create(:partner_admin) }
      let(:admin_partner) { user.partners.first }

      before { sign_in user }

      it 'shows only their partners in selector' do
        get new_admin_calendar_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(admin_partner.name)
      end
    end

    context 'as a neighbourhood admin' do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let!(:partner_in_neighbourhood) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end

      before { sign_in user }

      it 'shows partners in their neighbourhood' do
        get new_admin_calendar_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner_in_neighbourhood.name)
      end
    end
  end

  describe 'GET /admin/calendars/:id/edit' do
    let(:user) { create(:root_user) }
    let!(:partner1) { create(:partner) }
    let!(:partner2) { create(:partner) }
    let(:calendar) do
      cal = build(:calendar, partner: partner1, importer_mode: 'ical')
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end

    before { sign_in user }

    it 'shows the edit form' do
      get edit_admin_calendar_url(calendar, host: admin_host)
      expect(response).to be_successful
    end

    it 'shows current importer selection' do
      get edit_admin_calendar_url(calendar, host: admin_host)
      expect(response.body).to include('ical')
    end
  end

  describe 'PUT /admin/calendars/:id' do
    let(:user) { create(:partner_admin) }
    let(:admin_partner) { user.partners.first }
    let(:calendar) do
      cal = build(:calendar, partner: admin_partner, importer_mode: 'ical')
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end

    before { sign_in user }

    it 'allows changing importer mode' do
      put admin_calendar_url(calendar, host: admin_host),
          params: { calendar: calendar.attributes.merge('importer_mode' => 'eventbrite') }

      calendar.reload
      expect(calendar.importer_mode).to eq('eventbrite')
    end
  end
end
