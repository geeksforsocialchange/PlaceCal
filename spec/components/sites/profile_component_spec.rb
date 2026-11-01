# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Sites::Profile, type: :component do
  let(:user) do
    double(
      full_name: "Jane Doe",
      email: "jane@example.com",
      phone: "01onal234 567890",
      avatar: double(retina: double(url: nil))
    )
  end

  it "renders user name" do
    render_inline(described_class.new(user:))

    expect(page).to have_text("Jane Doe")
  end

  it "renders user email" do
    render_inline(described_class.new(user:))

    expect(page).to have_text("jane@example.com")
  end

  it "renders phone when present" do
    render_inline(described_class.new(user:))

    expect(page).to have_text("01onal234 567890")
  end

  context "when phone is blank" do
    let(:user) do
      double(
        full_name: "Jane Doe",
        email: "jane@example.com",
        phone: "",
        avatar: double(retina: double(url: nil))
      )
    end

    it "does not show call text" do
      render_inline(described_class.new(user:))

      expect(page).not_to have_text("Call on")
    end
  end

  it "renders the heading and an email link" do
    render_inline(described_class.new(user:))

    expect(page).to have_css("[data-scope='profile'][data-part='root']")
    expect(page).to have_css("h3", text: I18n.t("components.profile.heading"))
    expect(page).to have_link("jane@example.com", href: "mailto:jane@example.com")
  end
end
