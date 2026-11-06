# frozen_string_literal: true

require "rails_helper"

RSpec.describe IndexNowSubmission do
  subject(:submission) { described_class.new(since: 1.day.ago) }

  let(:ward) { create(:riverside_ward) }
  let(:address) { create(:address, neighbourhood: ward) }
  let!(:partner) { create(:partner, address:) }
  let!(:event) { create(:event, organiser: partner, address:, dtstart: 1.day.from_now) }
  let(:bodies) { [] }

  before do
    stub_request(:post, described_class::ENDPOINT.to_s).to_return do |request|
      bodies << JSON.parse(request.body)
      { status: 200 }
    end
  end

  def body_for(host) = bodies.find { |body| body["host"] == host }

  it "submits changed pages to the directory, with its key" do
    submission.call

    expect(body_for("placecal.org")).to include(
      "key" => described_class::KEY,
      "keyLocation" => "https://placecal.org/indexnow-key.txt",
      "urlList" => include("https://placecal.org/partners/#{partner.slug}", "https://placecal.org/events/#{event.id}")
    )
  end

  it "submits a served-domain site's pages on its own host" do
    serve_hosts("transdimension.uk")
    create(:site, slug: "trans-dimension", domain: "transdimension.uk", is_published: true).neighbourhoods << ward

    submission.call

    expect(body_for("transdimension.uk")["urlList"]).to include(
      "https://transdimension.uk/partners/#{partner.slug}", "https://transdimension.uk/events/#{event.id}"
    )
  end

  it "skips sites on a subdomain, whose pages are canonical on the directory" do
    create(:site, slug: "hulme", is_published: true).neighbourhoods << ward

    submission.call

    expect(bodies.pluck("host")).to eq(["placecal.org"])
  end

  it "leaves out events from hidden organisers" do
    hidden = create(:partner, address:, hidden: true, hidden_reason: "Moderated", hidden_blame_id: create(:user).id)
    event = create(:event, organiser: hidden, address:, dtstart: 1.day.from_now)

    submission.call

    expect(body_for("placecal.org")["urlList"]).not_to include("https://placecal.org/events/#{event.id}")
  end

  it "leaves out unchanged pages" do
    described_class.new(since: 1.hour.from_now).call

    expect(bodies).to be_empty
  end

  it "leaves out past events" do
    past = create(:event, organiser: partner, address:, dtstart: 2.days.ago, dtend: 2.days.ago)

    submission.call

    expect(body_for("placecal.org")["urlList"]).not_to include("https://placecal.org/events/#{past.id}")
  end

  it "logs a failure rather than raising" do
    stub_request(:post, described_class::ENDPOINT.to_s).to_timeout
    allow(Rails.logger).to receive(:warn)

    expect { submission.call }.not_to raise_error
    expect(Rails.logger).to have_received(:warn).with(/IndexNow failed/)
  end
end
