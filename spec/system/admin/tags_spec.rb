# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Tags', :slow, type: :system do
  include_context 'admin login'

  let!(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let!(:partner_admin) do
    partner = create(:riverside_community_hub)
    create(:partner_admin, partner: partner)
  end
  let!(:partner) { partner_admin.partners.first }
  let!(:partner_two) { create(:oldtown_library) }
  let!(:partnership) { create(:partnership) }

  describe 'select2 inputs on tag form' do
    it 'allows selecting partners and users', :aggregate_failures do
      click_link 'Tags'
      click_link partnership.name
      await_select2

      # Select partners
      partners_node = select2_node('tag_partners')
      select2 partner.name, partner_two.name, xpath: partners_node.path
      assert_select2_multiple [partner.name, partner_two.name], partners_node

      # Select users (for Partnership tags)
      users_node = select2_node('tag_users')
      select2 admin_user.to_s, partner_admin.to_s, xpath: users_node.path
      assert_select2_multiple [admin_user.to_s, partner_admin.to_s], users_node

      click_button 'Save'

      # Verify data persists
      click_link 'Tags'
      click_link partnership.name
      await_select2

      partners_node = select2_node('tag_partners')
      assert_select2_multiple [partner.name, partner_two.name], partners_node

      users_node = select2_node('tag_users')
      assert_select2_multiple [admin_user.to_s, partner_admin.to_s], users_node
    end
  end
end
