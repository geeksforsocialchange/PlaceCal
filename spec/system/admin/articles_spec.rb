# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Articles", :slow, type: :system do
  include_context "admin login"

  let!(:partner) { create(:riverside_community_hub) }
  let!(:partner_two) { create(:oldtown_library) }
  let!(:partnership) { create(:partnership) }
  let!(:article) { create(:article) }

  describe "select2 inputs on article form" do
    it "allows selecting author, partners and tags", :aggregate_failures do
      click_link "Articles"
      await_datatables

      click_link article.title

      # Select author
      author_node = select2_node("article_author")
      select2 admin_user.to_s, xpath: author_node.path
      assert_select2_single admin_user.to_s, author_node

      # Select partners (multiple)
      partners_node = select2_node("article_partners")
      select2 partner.name, partner_two.name, xpath: partners_node.path
      assert_select2_multiple [partner.name, partner_two.name], partners_node

      # Select tags
      tags_node = select2_node("article_tags")
      select2 partnership.name, xpath: tags_node.path
      assert_select2_multiple [partnership.name_with_type], tags_node

      click_button "Save Article"

      # Verify data persists
      click_link "Articles"
      await_datatables
      click_link article.title

      author_node = select2_node("article_author")
      assert_select2_single admin_user.to_s, author_node

      partners_node = select2_node("article_partners")
      assert_select2_multiple [partner.name, partner_two.name], partners_node

      tags_node = select2_node("article_tags")
      assert_select2_multiple [partnership.name_with_type], tags_node
    end
  end
end
