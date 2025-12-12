# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Neighbourhoods', :slow, type: :system do
  include_context 'admin login'

  let!(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let!(:riverside_ward) { create(:riverside_ward) }

  describe 'select2 inputs on neighbourhood form' do
    it 'allows selecting users', :aggregate_failures do
      click_link 'Neighbourhoods'

      # Find and click the first neighbourhood
      find_element_and_retry_if_stale do
        within page.all(:css, '.odd')[0] do
          click_link
        end
      end

      click_link 'Edit'

      # Select users
      users_node = select2_node('neighbourhood_users')
      select2 admin_user.to_s, neighbourhood_admin.to_s, xpath: users_node.path
      assert_select2_multiple [admin_user.to_s, neighbourhood_admin.to_s], users_node

      click_button 'Save'

      # Navigate back to verify data persists
      click_link 'Neighbourhoods'

      find_element_and_retry_if_stale do
        within page.all(:css, '.odd')[0] do
          click_link
        end
      end

      find_element_and_retry_if_not_found do
        click_link 'Edit'
      end

      find_element_and_retry_if_stale do
        find_element_and_retry_if_not_found do
          users_node = select2_node('neighbourhood_users')
          assert_select2_multiple [admin_user.to_s, neighbourhood_admin.to_s], users_node
        end
      end
    end
  end
end
