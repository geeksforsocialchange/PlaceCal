require 'test_helper'

class ArticlePolicyTest < ActiveSupport::TestCase
  def setup
    @root = build(:root)
    @editor = build(:editor)

    @partner_admin = build(:partner_admin)
    @neighbourhood_admin = build(:neighbourhood_region_admin)

    # Give the Neighbourhood admin a partner in one of their districts :)
    neighbourhood = @neighbourhood_admin.neighbourhoods.first.children.first # TODO: Ewwwwww
    partner = build(:partner, address: build(:address, neighbourhood: neighbourhood))

    assert @neighbourhood_admin.owned_neighbourhood_ids.include?(partner.address.neighbourhood.id)
    # pp Partner.from_neighbourhoods_and_service_areas(@neighbourhood_admin.owned_neighbourhood_ids)
    # => false (because sql)

    @citizen = build(:citizen)
  end

  def test_show
    assert allows_access(@root, Article, :index)
    assert allows_access(@editor, Article, :index)
    assert allows_access(@partner_admin, Article, :index)
    assert allows_access(@neighbourhood_admin, Article, :index)

    assert denies_access(@citizen, Article, :index)
  end

  def test_create
    assert allows_access(@root, Article, :create)
    assert allows_access(@editor, Article, :create)

    # Currently no way to test this due to SQL requests for objects not being mocked(?) :(
    # assert allows_access(@partner_admin, Article, :create)
    # assert allows_access(@neighbourhood_admin, Article, :create)

    assert denies_access(@citizen, Article, :create)
  end

  def test_update
    assert allows_access(@root, Article, :update)
    assert allows_access(@editor, Article, :update)
    assert allows_access(@partner_admin, Article, :update)
    assert allows_access(@neighbourhood_admin, Article, :update)

    assert denies_access(@citizen, Article, :update)
  end

  def test_destroy
    assert allows_access(@root, Article, :destroy)
    assert allows_access(@editor, Article, :destroy)
    assert allows_access(@partner_admin, Article, :destroy)
    assert allows_access(@neighbourhood_admin, Article, :destroy)

    assert denies_access(@citizen, Article, :destroy)
  end

  def test_scope; end
end
