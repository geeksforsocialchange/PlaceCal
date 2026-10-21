# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContactRequest do
  it "is valid with name, email and why" do
    expect(described_class.new(name: "A", email: "a@example.com", why: "Community")).to be_valid
  end

  it "requires name, email and why" do
    contact_request = described_class.new
    expect(contact_request).not_to be_valid
    expect(contact_request.errors.attribute_names).to include(:name, :email, :why)
  end

  describe "#submit" do
    include ActiveJob::TestHelper

    it "queues the enquiry mail with serializable arguments when valid" do
      site = create(:site)
      contact_request = described_class.new(name: "A", email: "a@example.com", why: "Community", site:, demo: true)

      expect { contact_request.submit }.to have_enqueued_mail(JoinMailer, :join_us)
        .with(attributes: hash_including("name" => "A", "email" => "a@example.com", "why" => "Community"),
              site_id: site.id, demo: true)
    end

    it "sends the mail when the queued job runs" do
      contact_request = described_class.new(name: "A", email: "a@example.com", why: "Community")

      expect { perform_enqueued_jobs { contact_request.submit } }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(ActionMailer::Base.deliveries.last.body.encoded).to include("Community")
    end

    it "does not queue a mail when invalid" do
      expect { described_class.new.submit }.not_to have_enqueued_mail(JoinMailer, :join_us)
    end
  end
end
