# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Pages', type: :request do
  let(:site) { create(:site, slug: 'test-site') }
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  describe 'GET / (home page)' do
    it 'returns successful response' do
      get root_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it 'displays site name' do
      get root_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include(site.name)
    end
  end

  describe 'GET /privacy' do
    it 'returns successful response' do
      # Note: /about doesn't exist, but /privacy does
      get '/privacy', headers: { 'Host' => "#{site.slug}.lvh.me" }
      expect(response).to be_successful
    end
  end

  describe 'site not found' do
    it 'handles non-existent site slug' do
      get root_url(host: 'nonexistent.lvh.me')
      # Should either 404 or redirect
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end
end
