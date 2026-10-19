# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe "Directory home caching", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:store) { ActiveSupport::Cache::FileStore.new(Dir.mktmpdir) }

  before do
    allow(Rails).to receive(:cache).and_return(store)
    allow(store).to receive(:delete_entry).and_call_original
  end

  after { travel_back }

  it "refreshes expired homepage entries in place instead of deleting them" do
    store.write("directory/partner_event_counts", {}, expires_in: 1.second)
    travel 2.seconds

    get "/"

    expect(response).to have_http_status(:ok)
    expect(store).not_to have_received(:delete_entry)
  end

  it "refreshes the expired stats entry in place instead of deleting it" do
    store.write(DirectoryStatsQuery::CACHE_KEY, {}, expires_in: 1.second)
    travel 2.seconds

    DirectoryStatsQuery.fetch_cached

    expect(store).not_to have_received(:delete_entry)
  end
end
