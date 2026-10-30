# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Field, type: :component do
  it "labels the control it wraps" do
    render_inline(described_class.new(label: "Search", id: "q")) { |field| field.input(id: "q") }

    expect(page).to have_field("Search")
  end

  it "links a hint to the control through aria-describedby" do
    component = described_class.new(label: "New password", id: "pw", hint: "(8 characters minimum)")
    render_inline(component) { |field| field.input(id: "pw", aria: { describedby: field.hint_id }) }

    expect(page).to have_css("p#pw_hint", text: "(8 characters minimum)")
    expect(page).to have_css("input#pw[aria-describedby='pw_hint']")
  end

  it "marks a required field with an asterisk that screen readers skip" do
    render_inline(described_class.new(label: "Name", id: "name", required: true)) { |field| field.input(id: "name") }

    expect(page).to have_css("label[for='name'] [aria-hidden='true']", text: "*")
  end

  it "marks an optional field in words" do
    render_inline(described_class.new(label: "Phone", id: "phone", required: false)) { |field| field.input(id: "phone") }

    expect(page).to have_css("label[for='phone']", text: "optional")
  end

  it "has no hint id without a hint" do
    render_inline(described_class.new(label: "Email", id: "email")) { |field| field.input(id: "email", aria: { describedby: field.hint_id }) }

    expect(page).not_to have_css("[aria-describedby]")
  end
end
