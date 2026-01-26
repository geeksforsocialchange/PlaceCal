# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Articles", :slow, type: :system do
  include_context "admin login"

  let!(:partner) { create(:riverside_community_hub) }
  let!(:partner_two) { create(:oldtown_library) }
  let!(:partnership) { create(:partnership) }
  let!(:article) { create(:article) }

  describe "article form inputs" do
    it "allows selecting author, partners and tags", :aggregate_failures do
      click_link "Articles"
      await_datatables

      click_link article.title

      # Select author (on Text tab, which is default)
      author_node = tom_select_node("article_author")
      tom_select admin_user.to_s, xpath: author_node.path
      assert_tom_select_single admin_user.to_s, author_node

      # Navigate to References tab for partners and tags
      accept_confirm do
        find('input[aria-label*="References"]').click
      end

      # Select partners using stacked list selector
      stacked_list_select partner.name, partner_two.name, wrapper_class: "article_partners"
      assert_stacked_list_items [partner.name, partner_two.name], "article_partners"

      # Select tags using stacked list selector
      stacked_list_select partnership.name, wrapper_class: "article_tags"
      assert_stacked_list_items [partnership.name], "article_tags"

      click_button "Save"

      # Verify data persists
      click_link "Articles"
      await_datatables
      click_link article.title

      # Ensure we're on the Text tab (tab state may be stored)
      find('input[aria-label*="Text"]').click

      author_node = tom_select_node("article_author")
      assert_tom_select_single admin_user.to_s, author_node

      # Navigate to References tab to verify partners and tags
      find('input[aria-label*="References"]').click

      assert_stacked_list_items [partner.name, partner_two.name], "article_partners"
      assert_stacked_list_items [partnership.name], "article_tags"
    end
  end
end
