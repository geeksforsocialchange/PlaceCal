# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Input, type: :component do
  it "renders a text input by default" do
    render_inline(described_class.new(name: "q", id: "q"))

    expect(page).to have_css("input[type='text'][name='q']#q")
  end

  it "passes the type and attributes through" do
    render_inline(described_class.new(type: "email", name: "user[email]", value: "a@b.org", autocomplete: "email"))

    input = page.find("input[type='email']")
    expect(input.value).to eq("a@b.org")
    expect(input[:autocomplete]).to eq("email")
  end

  it "keeps extra classes alongside its own" do
    render_inline(described_class.new(class: "mt-2"))

    expect(page).to have_css("input.mt-2.rounded-sm")
  end

  it "adds a Show button for the password field, hidden until JavaScript connects" do
    render_inline(described_class.new(type: "password", reveal: true, id: "user_password"))

    expect(page).to have_css("[data-controller='password-reveal'] input[type='password']#user_password")
    expect(page).to have_css("button[hidden][aria-controls='user_password']", text: "Show", visible: :all)
  end
end
