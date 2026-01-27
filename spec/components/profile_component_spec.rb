# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileComponent, type: :component do
  let(:user) do
    double(
      full_name: "Jane Doe",
      email: "jane@example.com",
      phone: "01onal234 567890",
      avatar: double(retina: double(url: nil))
    )
  end

  it "renders user name" do
    render_inline(described_class.new(user: user))

    expect(page).to have_text("Jane Doe")
  end

  it "renders user email" do
    render_inline(described_class.new(user: user))

    expect(page).to have_text("jane@example.com")
  end

  it "renders phone when present" do
    render_inline(described_class.new(user: user))

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
      render_inline(described_class.new(user: user))

      expect(page).not_to have_text("Call on")
    end
  end

  it "renders profile structure" do
    render_inline(described_class.new(user: user))

    expect(page).to have_css(".profile")
    expect(page).to have_css(".profile__title")
    expect(page).to have_css(".profile__details")
  end
end
