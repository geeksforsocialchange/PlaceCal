# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ContactDetails, type: :phlex do
  # see spec/factories/partners.rb and lib/normal_island.rb
  let(:contact_partner) { create(:riverside_community_hub) }
  let(:contact_email) { "info@example.org" }
  let(:contact_phone) { "01234 567 890" }
  let(:contact_url) { "site.example.org" }

  let(:fallback_partner) { create(:oldtown_library) }
  let(:fallback_email) { "" }
  let(:fallback_phone) { "" }
  let(:fallback_url) { "" }

  it "renders contact details" do
    render_inline(described_class.new(partner: contact_partner,
                                      email: contact_email,
                                      phone: contact_phone,
                                      url: contact_url))

    expect(page).to have_text(contact_phone)
    expect(page).to have_text(contact_url)
    expect(page).to have_text(contact_email)
    expect(page).to have_text("rchfb")
    expect(page).to have_text("rchtwit")
    expect(page).to have_text("rchinsta")
  end

  it "renders no contact details fallback" do
    render_inline(described_class.new(partner: fallback_partner,
                                      email: fallback_email,
                                      phone: fallback_phone,
                                      url: fallback_url))

    expect(page).to have_text("No contact information - let us know!")
  end
end
