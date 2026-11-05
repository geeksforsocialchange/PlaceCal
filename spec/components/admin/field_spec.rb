# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::Field, type: :phlex do
  def render_field(**props)
    render_inline(described_class.new(for: "partner_name", label: "Name", **props)) do |f|
      f.input(id: "partner_name", **f.aria)
    end
  end

  it "labels the control" do
    render_field

    expect(page).to have_css("fieldset.fieldset label[for='partner_name']", text: "Name")
    expect(page).to have_no_css("#partner_name[aria-describedby], #partner_name[aria-required]")
  end

  it "marks a required control, with the asterisk hidden from screen readers" do
    render_field(required: true)

    expect(page).to have_css("#partner_name[aria-required='true']")
    expect(page).to have_css("label span.text-error[aria-hidden='true']", text: I18n.t("admin.labels.required"))
  end

  it "describes the control by its hint" do
    render_field(hint: "Your organisation's name")

    expect(page).to have_css("#partner_name[aria-describedby='partner_name-hint']")
    expect(page).to have_css("p#partner_name-hint", text: "Your organisation's name")
  end

  it "describes the control by its character counter too" do
    render_field(hint: "One line", counter: 200)

    expect(page).to have_css("fieldset[data-controller='char-counter'][data-char-counter-max-value='200']")
    expect(page).to have_css("#partner_name[aria-describedby='partner_name-hint partner_name-counter']")
    expect(page).to have_css("#partner_name-counter[data-char-counter-target='counter']", text: "0 / 200")
  end

  it "renders content after the hint" do
    render_inline(described_class.new(for: "x", label: "X", hint: "Hint")) do |f|
      f.input(id: "x")
      f.after { f.div(class: "feedback") { "Checked" } }
    end

    expect(page.find("fieldset").all("p, div.feedback").map(&:text)).to eq(%w[Hint Checked])
  end
end
