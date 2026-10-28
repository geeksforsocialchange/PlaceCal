# frozen_string_literal: true

require "rails_helper"

# Test env runs on :null_store, so this is where CI exercises the store staging and production use.
RSpec.describe SolidCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  subject(:store) { described_class.new }

  it "keeps entries in the primary database" do
    store.write("og_image/test", "png bytes", expires_in: 1.week)

    expect(store.read("og_image/test")).to eq("png bytes")
    expect(SolidCache::Entry.count).to eq(1)
    expect(SolidCache::Entry.connection_pool).to equal(ActiveRecord::Base.connection_pool)
  end

  it "counts requests the way rack-attack throttles them" do
    freeze_time do
      cache = Rack::Attack::Cache.new(store:)
      2.times { cache.count("api/ip:192.0.2.1", 60) }

      expect(cache.count("api/ip:192.0.2.1", 60)).to eq(3)
    end
  end

  it "takes its size and age limits from config/cache.yml" do
    expect(store).to have_attributes(max_size: 256.megabytes, max_age: 1.week.to_i)
  end

  it "expires through a job in tests, never on its own thread" do
    # A batch size of 1 makes every write schedule expiry, instead of a 2% chance.
    eager = described_class.new(expiry_batch_size: 1)

    expect { eager.write("og_image/test", "png bytes") }.to have_enqueued_job(SolidCache::ExpiryJob).twice
  end
end
