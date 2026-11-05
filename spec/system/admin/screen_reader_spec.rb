# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin forms for screen readers", :slow, type: :system do
  include_context "admin login"

  let(:image) { Rails.root.join("spec/fixtures/files/test_image.jpg") }
  let!(:partner) { create(:riverside_community_hub, image: File.open(image)) }
  let!(:calendar) { create(:calendar, organiser: partner) }

  def attribute(selector, name)
    find(selector, visible: :all)[name]
  end

  def described_by(selector)
    attribute(selector, "aria-describedby").split.map { |id| find_by_id(id, visible: :all).text(:all).strip }
  end

  it "names tabs without their decorative emoji" do
    visit admin_url("/partners/#{partner.id}/edit")
    wait_for_form_tabs

    expect(page).to have_css("input.tab[aria-label='Basic Info'][data-icon]", visible: :all)
    expect(page).to have_no_css("input.tab[aria-label*='\u{1F4CB}']", visible: :all)
  end

  it "marks fields with a required asterisk as required" do
    visit admin_url("/partners/#{partner.id}/edit")

    expect(page).to have_css("#partner_name[aria-required='true']")
    expect(page).to have_no_css("#partner_summary[aria-required]")
  end

  it "reads each field's hint and character counter with it" do
    visit admin_url("/partners/#{partner.id}/edit")

    expect(page).to have_css("#partner_summary[aria-describedby]")
    expect(described_by("#partner_summary")).to eq(
      [I18n.t("admin.partners.fields.summary_hint"), "#{partner.summary.length} / 200"]
    )
  end

  it "gives an existing image one file input" do
    visit admin_url("/partners/#{partner.id}/edit")

    expect(page).to have_css("input[type=file][name='partner[image]']", count: 1, visible: :all)
  end

  it "names a Tom Select field with its label, value and hint, and opens it only on request" do
    visit admin_url("/calendars/#{calendar.id}/edit")
    input = find("#calendar_organiser_id-ts-control", visible: :all)

    expect(input["aria-required"]).to eq("true")
    names = input["aria-labelledby"].split.map { |id| find_by_id(id, visible: :all).text(:all).strip }
    expect(names.join(" ")).to include(partner.name)
    expect(input["aria-describedby"]).to be_present

    expanded = "#calendar_organiser_id-ts-control[aria-expanded='%s']"
    page.execute_script("arguments[0].focus()", input)
    expect(page).to have_css("#{format(expanded, 'false')}:focus", visible: :all)

    input.send_keys(:down)
    expect(page).to have_css(format(expanded, "true"), visible: :all)

    input.send_keys(:escape)
    expect(page).to have_css(format(expanded, "false"), visible: :all)
    find(".ts-wrapper:has(#calendar_organiser_id-ts-control) .ts-control").click
    expect(page).to have_css(format(expanded, "true"), visible: :all)
  end
end
