# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Collections", type: :request do
  let!(:collection) { create(:collection) }

  describe "GET /collections/:id" do
    it "shows collection page" do
      get collection_url(collection, host: "lvh.me")
      expect(response).to be_successful
    end

    it "displays collection name in title" do
      get collection_url(collection, host: "lvh.me")
      expect(response.body).to include(collection.name)
      expect(response.body).to include("PlaceCal")
    end

    it "displays collection name in hero" do
      get collection_url(collection, host: "lvh.me")
      expect(response.body).to include(collection.name)
    end
  end
end
