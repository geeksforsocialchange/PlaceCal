# frozen_string_literal: true

require 'test_helper'

class TagPolicyTest < ActiveSupport::TestCase
  def setup
    @root = create(:root)
    @non_root = create(:editor)

    @partner_admin = create(:partner_admin)
    @partnership_admin = create(:partnership_admin)

    @normal_tag = create(:tag)
    @system_tag = create(:tag, system_tag: true)
  end

  def test_update
    assert allows_access(@root, @normal_tag, :update)
    assert allows_access(@root, @system_tag, :update)

    assert denies_access(@partner_admin, @normal_tag, :update)
    assert denies_access(@partner_admin, @system_tag, :update)
    assert denies_access(@partnership_admin, @normal_tag, :update)
    assert denies_access(@partnership_admin, @system_tag, :update)
    assert denies_access(@non_root, @system_tag, :update)
  end

  test 'permitted_attributes have `type` when record is a Tag' do
    # as a basic tag
    policy = TagPolicy.new(@root, Tag.new)
    fields = policy.permitted_attributes

    assert_includes fields, :type, 'Expecting type field for basic tag'

    # as a sub-model type tag
    policy = TagPolicy.new(@root, Facility.new)
    fields = policy.permitted_attributes

    assert_not fields.include?(:type), 'Expecting type field to NOT be allowed for sub-model'
  end
end
