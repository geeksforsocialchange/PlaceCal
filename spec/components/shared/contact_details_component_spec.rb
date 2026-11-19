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
    expect(page).to have_text("rch.bsky.social")
    expect(page).to have_text("@rchinsta")
  end

  it "renders no contact details fallback" do
    render_inline(described_class.new(partner: fallback_partner,
                                      email: fallback_email,
                                      phone: fallback_phone,
                                      url: fallback_url))

    expect(page).to have_text("No contact information")
  end

  it "wraps each sites-variant link in an item span" do
    render_inline(described_class.new(partner: contact_partner,
                                      email: contact_email,
                                      phone: contact_phone,
                                      url: contact_url))

    expect(page).to have_css("span[data-scope='contact-details'][data-part='item'] a[href='tel:#{contact_phone}']", text: contact_phone)
    expect(page).to have_css("span[data-scope='contact-details'][data-part='item'] a[href='mailto:#{contact_email}']", text: contact_email)
    expect(page).to have_css("span[data-scope='contact-details'][data-part='item'] a[href='#{contact_url}']")
    expect(page).to have_css("span[data-scope='contact-details'][data-part='item'] a[href='https://www.facebook.com/rchfb']")
    expect(page).to have_css("span[data-scope='contact-details'][data-part='item'] a[href='https://bsky.app/profile/rch.bsky.social']")
    expect(page).to have_css("span[data-scope='contact-details'][data-part='item'] a[href='https://www.instagram.com/rchinsta/']")
  end

  it "marks the social links as social items, in the partner's order, each with its network's icon" do
    render_inline(described_class.new(partner: contact_partner))

    items = page.all("span[data-scope='contact-details'][data-part='item'][data-variant='social']")
    expect(items.map { it.find("a")[:href] }).to eq(contact_partner.social_links)
    expect(items.map { it.find("svg")["data-icon-name"] }).to eq(%w[contact_facebook contact_bluesky contact_instagram])
    expect(page).not_to have_css("span[data-scope='contact-details'][data-variant='social'] a[href^='mailto:']")
  end

  context "with links the partner added on other networks" do
    let(:partner) do
      build(:partner, social_links: ["https://social.coop/@hulmecc", "https://www.facebook.com/groups/hulme",
                                     "https://www.facebook.com/profile.php?id=123", "https://x.com/hulmecc",
                                     "https://hulme.example.org/newsletter"])
    end

    it "shows a handle where the address has one, and the address where it doesn't" do
      render_inline(described_class.new(partner:))

      expect(page).to have_link("@hulmecc@social.coop on Mastodon", href: "https://social.coop/@hulmecc")
      expect(page).to have_link("facebook.com/groups/hulme on Facebook", href: "https://www.facebook.com/groups/hulme")
      expect(page).to have_link("facebook.com/profile.php?id=123 on Facebook", href: "https://www.facebook.com/profile.php?id=123")
      expect(page).to have_link("@hulmecc on X", href: "https://x.com/hulmecc")
      expect(page).to have_link("hulme.example.org/newsletter", exact: true, href: "https://hulme.example.org/newsletter")
      expect(page).to have_css("[data-variant='social']:has(a[href='https://hulme.example.org/newsletter']) svg[data-icon-name='link']")
    end

    it "names an unrecognised site after its host in the network labels" do
      render_inline(described_class.new(partner:, social_labels: :network))

      expect(page).to have_link("Mastodon", title: "@hulmecc@social.coop")
      expect(page).to have_link("hulme.example.org", title: "hulme.example.org/newsletter")
    end

    it "lists every link in the rows variant" do
      render_inline(described_class.new(partner:, variant: :rows))

      expect(page).to have_link("@hulmecc@social.coop on Mastodon")
      expect(page).to have_link("@hulmecc on X")
      expect(page).to have_link("hulme.example.org/newsletter", exact: true)
    end
  end

  it "shows the contact card for a partner whose only contact is a social link" do
    render_inline(described_class.new(partner: build(:partner, social_links: ["https://bsky.app/profile/a.bsky.social"]), variant: :card))

    expect(page).to have_text("Get in touch")
    expect(page).to have_link("a.bsky.social on Bluesky")
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
      expect(page).to have_link("Facebook", title: "rchfb")
      expect(page).to have_link("Bluesky", title: "rch.bsky.social")
      expect(page).to have_link("Instagram", title: "@rchinsta")
      expect(page).not_to have_text("rchinsta")
    end

    it "leaves phone, email and website as they are" do
      expect(page).to have_link(contact_phone, href: "tel:#{contact_phone}")
      expect(page).to have_link(contact_email, href: "mailto:#{contact_email}")
      expect(page).to have_link(contact_url, href: contact_url)
    end
  end

  it "names the network in each handle link for screen readers" do
    render_inline(described_class.new(partner: contact_partner))

    expect(page).to have_link("rch.bsky.social on Bluesky", href: "https://bsky.app/profile/rch.bsky.social")
    expect(page).to have_link("@rchinsta on Instagram", href: "https://www.instagram.com/rchinsta/")
    expect(page).to have_css("a[href^='https://bsky.app/'] .sr-only", text: "on Bluesky")
  end

  it "names the network in each card handle link for screen readers" do
    render_inline(described_class.new(partner: contact_partner, variant: :card))

    expect(page).to have_link("rchfb on Facebook", href: "https://www.facebook.com/rchfb")
    expect(page).to have_link("@rchinsta on Instagram", href: "https://www.instagram.com/rchinsta/")
  end

  context "with a long website address" do
    let(:long_url) { "https://www.manchester.gov.uk/directory_record/44123/powerhouse_library/category/1234/libraries" }

    it "wraps the whole address beside an icon that keeps its size" do
      render_inline(described_class.new(partner: contact_partner, url: long_url, variant: :card))

      expect(page).to have_css("a[href='#{long_url}'] span.wrap-anywhere", text: "manchester.gov.uk/directory_record/44123/powerhouse_library/category/1234/libraries")
      expect(page).to have_css("a[href='#{long_url}'] svg[data-icon-name='contact_website'].shrink-0")
      expect(page).not_to have_css("svg[data-icon-name^='contact_']:not(.shrink-0)")
    end
  end

  context "tailwind variant" do
    it "renders contact details in card layout" do
      render_inline(described_class.new(partner: contact_partner,
                                        email: contact_email,
                                        phone: contact_phone,
                                        url: contact_url,
                                        variant: :card))

      expect(page).to have_text("Get in touch")
      expect(page).to have_text(contact_phone)
      expect(page).to have_text(contact_email)
      expect(page).to have_text(contact_url)
      expect(page).to have_text("rchfb")
      expect(page).to have_text("rch.bsky.social")
      expect(page).to have_text("@rchinsta")
    end

    it "renders nothing when no contact info" do
      render_inline(described_class.new(partner: fallback_partner,
                                        email: fallback_email,
                                        phone: fallback_phone,
                                        url: fallback_url,
                                        variant: :card))

      expect(page).not_to have_text("Get in touch")
      expect(page).not_to have_text("No contact information")
    end
  end
end
