# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Users", :slow, type: :system do
  include_context "admin login"

  # Create wards first to avoid duplicates
  let!(:riverside_ward) { create(:riverside_ward) }
  let!(:oldtown_ward) { create(:oldtown_ward) }
  let!(:neighbourhood_admin) { create(:neighbourhood_admin, neighbourhood: riverside_ward) }
  let!(:partner) { create(:riverside_community_hub, address: create(:address, neighbourhood: riverside_ward)) }
  let!(:partner_admin) { create(:partner_admin, partner: partner) }
  let!(:partner_two) { create(:oldtown_library, address: create(:address, neighbourhood: oldtown_ward)) }
  let!(:partnership) { create(:partnership) }

  describe "tom-select inputs on users form" do
    it "allows selecting partners, neighbourhoods and tags", :aggregate_failures do
      click_link "Users"

      # Edit a root user (has access to all potential tom-select inputs)
      # Click on the admin user's first name to edit
      click_link admin_user.first_name

      # Select partners
      partners_node = tom_select_node("user_partners")
      tom_select partner.name, partner_two.name, xpath: partners_node.path
      assert_tom_select_multiple [partner.name, partner_two.name], partners_node

      # Select neighbourhoods (displayed as "Name (Unit)" with titleized unit)
      neighbourhoods_node = tom_select_node("user_neighbourhoods")
      tom_select riverside_ward.name, oldtown_ward.name, xpath: neighbourhoods_node.path
      # UI displays unit titleized: "Riverside (Ward)" not "Riverside (ward)"
      assert_tom_select_multiple ["#{riverside_ward.name} (#{riverside_ward.unit.titleize})",
                                  "#{oldtown_ward.name} (#{oldtown_ward.unit.titleize})"], neighbourhoods_node

      # Select tags
      tags_node = tom_select_node("user_tags")
      tom_select partnership.name, xpath: tags_node.path
      assert_tom_select_multiple [partnership.name_with_type], tags_node

      click_button "Update"

      # Return to user to verify data persists
      click_link "Users"

      find_element_and_retry_if_stale do
        click_link admin_user.first_name
      end

      partners_node = tom_select_node("user_partners")
      assert_tom_select_multiple [partner.name, partner_two.name], partners_node

      neighbourhoods_node = tom_select_node("user_neighbourhoods")
      assert_tom_select_multiple ["#{riverside_ward.name} (#{riverside_ward.unit.titleize})",
                                  "#{oldtown_ward.name} (#{oldtown_ward.unit.titleize})"], neighbourhoods_node

      tags_node = tom_select_node("user_tags")
      assert_tom_select_multiple [partnership.name_with_type], tags_node
    end
  end
end
