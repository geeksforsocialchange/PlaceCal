# frozen_string_literal: true

require 'test_helper'

class ArticlePolicyTest < ActiveSupport::TestCase
  def setup
    @root = create(:root)
    @editor = create(:editor)

    @neighbourhood_admin = create(:neighbourhood_region_admin)

    @partner = create(:partner) do |partner|
      # Give the Neighbourhood admin a partner in one of their districts :)
      neighbourhood = @neighbourhood_admin.neighbourhoods.first.children.first # TODO: Ewwwwww
      partner.address.neighbourhood = neighbourhood
      partner.address.save!
    end
    # Double check that it's been looped together properly
    assert @neighbourhood_admin.owned_neighbourhood_ids.include?(@partner.address.neighbourhood.id)

    @partner_admin = create(:partner_admin) do |user|
      user.partners << @partner
      user.save!
    end

    @partnerless_neighbourhood_admin = create(:neighbourhood_region_admin)
    @citizen = create(:citizen)

    @unpartnered_article = create(:article)
    @article = create(:article) do |article|
      article.partners << @partner
      article.save!
    end
  end

  def test_show
    assert allows_access(@root, Article, :index)
    assert allows_access(@editor, Article, :index)
    assert allows_access(@partner_admin, Article, :index)
    assert allows_access(@neighbourhood_admin, Article, :index)

    assert denies_access(@partnerless_neighbourhood_admin, Article, :index)
    assert denies_access(@citizen, Article, :index)
  end

  def test_create
    assert allows_access(@root, Article, :create)
    assert allows_access(@editor, Article, :create)
    assert allows_access(@partner_admin, Article, :create)
    assert allows_access(@neighbourhood_admin, Article, :create)

    assert denies_access(@partnerless_neighbourhood_admin, Article, :create)
    assert denies_access(@citizen, Article, :create)
  end

  def test_update
    assert allows_access(@root, Article, :update)
    assert allows_access(@editor, Article, :update)
    assert allows_access(@partner_admin, Article, :update)
    assert allows_access(@neighbourhood_admin, Article, :update)

    assert denies_access(@partnerless_neighbourhood_admin, Article, :update)
    assert denies_access(@citizen, Article, :update)
  end

  def test_destroy
    assert allows_access(@root, Article, :destroy)
    assert allows_access(@editor, Article, :destroy)
    assert allows_access(@partner_admin, Article, :destroy)
    assert allows_access(@neighbourhood_admin, Article, :destroy)

    assert denies_access(@partnerless_neighbourhood_admin, Article, :destroy)
    assert denies_access(@citizen, Article, :destroy)
  end

  def test_scope
    root_scope = [@article, @unpartnered_article].sort_by(&:id)
    else_scope = [@article]
    none_scope = []

    assert_equal permitted_records(@root, Article).sort_by(&:id), root_scope
    assert_equal permitted_records(@editor, Article).sort_by(&:id), root_scope

    assert_equal permitted_records(@partner_admin, Article), else_scope
    assert_equal permitted_records(@neighbourhood_admin, Article), else_scope

    assert_equal permitted_records(@partnerless_neighbourhood_admin, Article), none_scope
    assert_equal permitted_records(@citizen, Article), none_scope
  end
end
