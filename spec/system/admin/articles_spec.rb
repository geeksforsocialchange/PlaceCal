# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Articles", :slow, type: :system do
  include_context "admin login"

  let!(:partner) { create(:riverside_community_hub) }
  let!(:partner_two) { create(:oldtown_library) }
  let!(:partnership) { create(:partnership) }
  let!(:article) { create(:article) }

  describe "tom-select inputs on article form" do
    it "allows selecting author, partners and tags", :aggregate_failures do
      click_link "Articles"
      await_datatables

      click_link article.title

      # Select author
      author_node = tom_select_node("article_author")
      tom_select admin_user.to_s, xpath: author_node.path
      assert_tom_select_single admin_user.to_s, author_node

      # Select partners (multiple)
      partners_node = tom_select_node("article_partners")
      tom_select partner.name, partner_two.name, xpath: partners_node.path
      assert_tom_select_multiple [partner.name, partner_two.name], partners_node

      # Select tags
      tags_node = tom_select_node("article_tags")
      tom_select partnership.name, xpath: tags_node.path
      assert_tom_select_multiple [partnership.name_with_type], tags_node

      click_button "Save Article"

      # Verify data persists
      click_link "Articles"
      await_datatables
      click_link article.title

      author_node = tom_select_node("article_author")
      assert_tom_select_single admin_user.to_s, author_node

      partners_node = tom_select_node("article_partners")
      assert_tom_select_multiple [partner.name, partner_two.name], partners_node

      tags_node = tom_select_node("article_tags")
      assert_tom_select_multiple [partnership.name_with_type], tags_node
    end
  end
end
