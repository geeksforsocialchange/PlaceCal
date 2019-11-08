# frozen_string_literal: true

require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  setup do
    @partner = create(:partner)
    @user = create(:user)
  end

  test 'updates user roles when saved' do
    assert_nil @user.role
    @partner.users << @user
    @partner.save
    assert_equal @user.role, 'partner_admin'
  end

  test 'fields validate' do
    partner = Partner.new
    partner.save

    # The only mandatory field is title (for now)
    assert_equal ["can't be blank", "must be at least 5 characters long"], partner.errors[:name], "must have a name"
    assert_equal 1, partner.errors.keys.length

    # Name must be unique
    partner.update(name: @partner.name)
    assert_equal ["has already been taken"], partner.errors[:name]

    # Name must be at least five charactors
    partner.update(name: "1234")
    assert_equal ["must be at least 5 characters long"], partner.errors[:name]

    # Url must be valid
    partner.update(url: "htp://bad-domain.co")
    assert_equal ["is invalid"], partner.errors[:url], "Partner must have a valid url"
    partner.update(url: "https://good-domain.com")
    refute partner.errors.key?(:url), "Valid URL not saved"

    # Twitter must be valid
    partner.update(twitter_handle: "@asdf")
    refute partner.errors.key?(:twitter_handle), "Valid twitter not saved"
    partner.update(twitter_handle: "asdf")
    refute partner.errors.key?(:twitter_handle), "Valid twitter not saved"
    partner.update(twitter_handle: "https://twitter.com/asdf")
    assert partner.errors.key?(:twitter_handle), "Should be account name not full URL"
    partner.update(twitter_handle: "asd£$%dsa")
    assert partner.errors.key?(:twitter_handle), "Invalid Twitter account name saved"

    # Facebook must be valid
    partner.update(facebook_link: "https://facebook.com/group-name")
    assert partner.errors.key?(:facebook_link), "Should be page name not full URL"
    partner.update(facebook_link: "Group-Name")
    assert partner.errors.key?(:facebook_link), "invalid Facebook page name saved"
    partner.update(facebook_link: "GroupName")
    refute partner.errors.key?(:facebook_link), "Valid page name not saved"
  end
end
