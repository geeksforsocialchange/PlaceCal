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

  it "applies the shared box and keeps extra classes" do
    render_inline(described_class.new(class: "mt-2"))

    input = page.find("input")
    expect(input[:class]).to include(described_class::BOX)
    expect(input[:class]).to include("mt-2")
  end
end
