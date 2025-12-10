# frozen_string_literal: true

require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  setup do
    @root = FactoryBot.create(:root)
    @neighbourhood_admin = FactoryBot.create(:neighbourhood_admin)
    @partner_admin = FactoryBot.create(:partner_admin)

    @partner = FactoryBot.create(:partner)

    @partner_in_neighbourhood = FactoryBot.create(:partner)
    @partner_in_neighbourhood.address.neighbourhood = @neighbourhood_admin.neighbourhoods.first
    @partner_in_neighbourhood.save!

    @partner_servicing_neighbourhood = FactoryBot.create(:partner)
    @partner_servicing_neighbourhood.service_area_neighbourhoods << @neighbourhood_admin.neighbourhoods.first
    @partner_servicing_neighbourhood.save!
  end

  test 'root user - options_for_partners with no user returns all allowed partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@root, Partner)
    end

    expected = Partner.order(:name).pluck(:name, :id)

    assert_equal(expected, options_for_partners)
  end

  test 'root user - options_for_partners with user returns all allowed partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@root, Partner)
    end

    expected = Partner.order(:name).pluck(:name, :id)

    assert_equal(expected, options_for_partners(@neighbourhood_admin))
  end

  test 'neighbourhood admin - options_for_partners with no user returns neighbourhood partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@neighbourhood_admin, Partner)
    end

    expected = [@partner_in_neighbourhood, @partner_servicing_neighbourhood].pluck(:name, :id)

    assert_equal(expected.sort, options_for_partners.sort)
  end

  test 'neighbourhood admin - options_for_partners with user returns neighbourhood partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@neighbourhood_admin, Partner)
    end

    expected = [@partner_in_neighbourhood, @partner_servicing_neighbourhood].pluck(:name, :id)

    assert_equal(expected.sort, options_for_partners(@neighbourhood_admin).sort)
  end

  test 'neighbourhood admin - options_for_partners with partner owning user returns neighbourhood partners & partners owned by user' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@neighbourhood_admin, Partner)
    end

    expected = [
      @partner_in_neighbourhood,
      @partner_servicing_neighbourhood,
      @partner_admin.partners.first
    ].pluck(:name, :id)

    assert_equal(expected.sort, options_for_partners(@partner_admin).sort)
  end

  test 'neighbourhood admin - permitted_options only shows neighbourhood partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@neighbourhood_admin, Partner)
    end

    expected = [
      @partner_in_neighbourhood,
      @partner_servicing_neighbourhood
    ].pluck(:id)

    assert_equal(expected.sort, permitted_options_for_partners.sort)
  end

  test 'root admin - permitted_options shows all partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@root, Partner)
    end

    expected = Partner.all.pluck(:id)

    assert_equal(expected.sort, permitted_options_for_partners.sort)
  end
end
