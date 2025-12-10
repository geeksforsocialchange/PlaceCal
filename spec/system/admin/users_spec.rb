# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Users', :slow, type: :system do
  include_context 'admin login'

  let!(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let!(:partner_admin) do
    partner = create(:riverside_community_hub)
    create(:partner_admin, partner: partner)
  end
  let!(:partner) { partner_admin.partners.first }
  let!(:partner_two) { create(:oldtown_library) }
  let!(:partnership) { create(:partnership) }
  let!(:riverside_ward) { create(:riverside_ward) }
  let!(:oldtown_ward) { create(:oldtown_ward) }

  describe 'select2 inputs on users form' do
    it 'allows selecting partners, neighbourhoods and tags', :aggregate_failures do
      click_link 'Users'

      # Edit a root user (has access to all potential select2 inputs)
      datatable_1st_row = page.all(:css, '.odd')[0]
      within datatable_1st_row do
        click_link 'Place'
      end

      # Select partners
      partners_node = select2_node('user_partners')
      select2 partner.name, partner_two.name, xpath: partners_node.path
      assert_select2_multiple [partner.name, partner_two.name], partners_node

      # Select neighbourhoods
      neighbourhoods_node = select2_node('user_neighbourhoods')
      select2 riverside_ward.name, oldtown_ward.name, xpath: neighbourhoods_node.path
      assert_select2_multiple [riverside_ward.name, oldtown_ward.name], neighbourhoods_node

      # Select tags
      tags_node = select2_node('user_tags')
      select2 partnership.name, xpath: tags_node.path
      assert_select2_multiple [partnership.name_with_type], tags_node

      click_button 'Update'

      # Return to user to verify data persists
      click_link 'Users'

      find_element_and_retry_if_stale do
        within page.all(:css, '.odd')[0] do
          click_link 'Place'
        end
      end

      partners_node = select2_node('user_partners')
      assert_select2_multiple [partner.name, partner_two.name], partners_node

      neighbourhoods_node = select2_node('user_neighbourhoods')
      assert_select2_multiple [riverside_ward.name, oldtown_ward.name], neighbourhoods_node

      tags_node = select2_node('user_tags')
      assert_select2_multiple [partnership.name_with_type], tags_node
    end
  end
end
