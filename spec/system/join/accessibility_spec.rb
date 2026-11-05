# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Join site accessibility", :slow, type: :system do
  include_context "normal island data"

  {
    "the homepage" => "/",
    "the who it's for index" => "/who-its-for",
    "an audience page" => "/who-its-for/community-groups",
    "the features page" => "/features",
    "our story" => "/our-story",
    "the pricing page" => "/pricing",
    "the book a demo form" => "/book-a-demo"
  }.each do |name, path|
    it "has no accessibility violations on #{name}" do
      visit join_url(path)
      expect(page).to be_axe_clean
    end
  end
end
