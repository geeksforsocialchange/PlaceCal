# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Join site accessibility", :slow, type: :system do
  include_context "normal island data"

  it "homepage has no accessibility violations" do
    visit join_url("/")
    expect(page).to be_axe_clean
  end

  it "who-its-for index has no accessibility violations" do
    visit join_url("/who-its-for")
    expect(page).to be_axe_clean
  end

  it "audience page has no accessibility violations" do
    visit join_url("/who-its-for/community-groups")
    expect(page).to be_axe_clean
  end

  it "features page has no accessibility violations" do
    visit join_url("/features")
    expect(page).to be_axe_clean
  end

  it "our story page has no accessibility violations" do
    visit join_url("/our-story")
    expect(page).to be_axe_clean
  end

  it "pricing page has no accessibility violations" do
    visit join_url("/pricing")
    expect(page).to be_axe_clean
  end

  it "book-a-demo form has no accessibility violations" do
    visit join_url("/book-a-demo")
    expect(page).to be_axe_clean
  end
end
