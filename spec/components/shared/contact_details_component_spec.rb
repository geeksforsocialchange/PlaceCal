# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Shared::ContactDetails, type: :phlex do
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

    expect(page).to have_text("No contact information")
  end

  it "gives each scss-variant link a channel class, wrapped in an item span" do
    render_inline(described_class.new(partner: contact_partner,
                                      email: contact_email,
                                      phone: contact_phone,
                                      url: contact_url))

    expect(page).to have_css("span.contact_details__item a.contact_details__phone", text: contact_phone)
    expect(page).to have_css("span.contact_details__item a.contact_details__email", text: contact_email)
    expect(page).to have_css("span.contact_details__item a.contact_details__website")
    expect(page).to have_css("span.contact_details__item a.contact_details__facebook")
    expect(page).to have_css("span.contact_details__item a.contact_details__twitter")
    expect(page).to have_css("span.contact_details__item a.contact_details__instagram")
  end

  it "marks the social links as social items" do
    render_inline(described_class.new(partner: contact_partner))

    expect(page).to have_css("span.contact_details__item--social", count: 3)
    expect(page).not_to have_css("span.contact_details__item--social a.contact_details__email")
  end

  context "with social_labels: :network" do
    before do
      render_inline(described_class.new(partner: contact_partner,
                                        email: contact_email,
                                        phone: contact_phone,
                                        url: contact_url,
                                        social_labels: :network))
    end

    it "names each social link after its network, keeping the handle in the title" do
      expect(page).to have_css("a.contact_details__facebook[title='rchfb']", text: "Facebook")
      expect(page).to have_css("a.contact_details__twitter[title='@rchtwit']", text: "Twitter")
      expect(page).to have_css("a.contact_details__instagram[title='@rchinsta']", text: "Instagram")
      expect(page).not_to have_text("rchtwit")
    end

    it "leaves phone, email and website as they are" do
      expect(page).to have_css("a.contact_details__phone", text: contact_phone)
      expect(page).to have_css("a.contact_details__email", text: contact_email)
      expect(page).to have_css("a.contact_details__website", text: contact_url)
    end
  end

  context "tailwind variant" do
    it "renders contact details in card layout" do
      render_inline(described_class.new(partner: contact_partner,
                                        email: contact_email,
                                        phone: contact_phone,
                                        url: contact_url,
                                        variant: :tailwind))

      expect(page).to have_text("Get in touch")
      expect(page).to have_text(contact_phone)
      expect(page).to have_text(contact_email)
      expect(page).to have_text(contact_url)
      expect(page).to have_text("Facebook")
      expect(page).to have_text("@rchtwit")
      expect(page).to have_text("@rchinsta")
    end

    it "renders nothing when no contact info" do
      render_inline(described_class.new(partner: fallback_partner,
                                        email: fallback_email,
                                        phone: fallback_phone,
                                        url: fallback_url,
                                        variant: :tailwind))

      expect(page).not_to have_text("Get in touch")
      expect(page).not_to have_text("No contact information")
    end
  end
end
