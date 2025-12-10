# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Events', type: :request do
  let(:site) { create(:site, slug: 'test-site') }
  let(:ward) { create(:riverside_ward) }
  let(:partner) { create(:riverside_partner) }

  before do
    site.neighbourhoods << ward
  end

  describe 'GET /events' do
    let!(:events) do
      create_list(:event, 5,
                  partner: partner,
                  dtstart: 1.day.from_now,
                  address: partner.address)
    end

    it 'returns successful response' do
      get events_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it 'displays events' do
      get events_url(host: "#{site.slug}.lvh.me")
      events.each do |event|
        expect(response.body).to include(event.summary)
      end
    end
  end

  describe 'GET /events/:id' do
    let(:event) do
      create(:event,
             partner: partner,
             summary: 'Test Event',
             dtstart: 1.day.from_now,
             address: partner.address)
    end

    it 'shows the event details' do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
      expect(response.body).to include(event.summary)
    end

    it 'shows partner information' do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.name)
    end
  end

  describe 'GET /events with date filter' do
    let!(:today_event) do
      create(:event,
             partner: partner,
             summary: 'Today Event',
             dtstart: Time.current.beginning_of_day + 10.hours,
             address: partner.address)
    end
    let!(:future_event) do
      create(:event,
             partner: partner,
             summary: 'Future Event',
             dtstart: 7.days.from_now,
             address: partner.address)
    end

    it 'filters events by date' do
      get events_url(host: "#{site.slug}.lvh.me", params: { date: Date.current.to_s })
      expect(response).to be_successful
    end
  end
end
