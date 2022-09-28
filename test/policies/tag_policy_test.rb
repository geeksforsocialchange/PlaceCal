# frozen_string_literal: true

require "test_helper"

class TagPolicyTest < ActiveSupport::TestCase
  def setup
    @root = create(:root)
    @non_root = create(:editor)

    @normal_tag = create(:tag)
    @system_tag = create(:tag, system_tag: true)
  end

  def test_update
    @non_root.tags << @normal_tag

    assert allows_access(@root, @normal_tag, :update)
    assert allows_access(@non_root, @normal_tag, :update)

    assert allows_access(@root, @system_tag, :update)
    assert denies_access(@non_root, @system_tag, :update)
  end
end
