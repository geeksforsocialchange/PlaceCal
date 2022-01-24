# frozen_string_literal: true

require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  setup do
    @partner = create(:partner)
    @user = create(:user)
  end

  test 'updates user roles when saved' do
    @partner.users << @user
    @partner.save
    assert @user.partner_admin?
  end

  test 'validate name length' do
    partner = Partner.new
    partner.update(name: '1234')

    # The only mandatory field is name (for now)
    assert error_map = partner.errors.where(:name, :too_short).first
    assert_equal 'must be at least 5 characters long', error_map.options[:message]
    assert_equal 1, partner.errors.attribute_names.length
  end

  test 'validate uniqueness' do
    partner = Partner.new
    # Name must be unique
    partner.update(name: @partner.name)
    assert_equal ['has already been taken'], partner.errors[:name]
  end

  test 'validate no summary or description' do
    partner = Partner.new

    partner.update(name: 'Test Partner')
    assert partner.errors.empty?
  end

  test 'validate summary without description' do
    partner = Partner.new

    partner.update(name: "Test Partner", summary: "This is a test partner used for testing :)")
    assert partner.errors.empty?, 'Should be able to submit a summary'
  end

  test 'validate description without summary' do
    partner = Partner.new

    partner.update(name: 'Test Partner', description: 'This is a test partner used for testing :)')
    assert_equal ['cannot have a description without a summary'],
                 partner.errors[:summary],
                 'Should not be able to have a description without summary'
  end

  test 'validate description and summary' do
    partner = Partner.new

    partner.update(name: 'Test Partner',
                   summary: 'This is a test summary wheee :)',
                   description: 'This is a test partner used for testing :)')
    assert partner.errors.empty?, 'Should be able to submit a summary and description'
  end

  test 'validate summary length' do
    partner = Partner.new
    # We can submit a 200 character summary
    partner.update(name: 'Test Partner', summary: ''.ljust(200, 'a'))
    assert partner.errors.empty?, '200 character summary should be valid'

    # But not a 201 character summary
    partner.update(name: 'Test Partner', summary: ''.ljust(201, 'a'))
    assert partner.errors.key?(:summary), 'maximum length is 200 characters'
  end

  test 'validate url' do
    partner = Partner.new
    # Url must be valid
    partner.update(url: 'htp://bad-domain.co')
    assert_equal ['is invalid'], partner.errors[:url], 'Partner must have a valid url'
    partner.update(url: 'https://good-domain.com')
    refute partner.errors.key?(:url), 'Valid URL not saved'
  end

  test 'validate twitter' do
    partner = Partner.new
    # Twitter must be valid
    partner.update(twitter_handle: '@asdf')
    refute partner.errors.key?(:twitter_handle), 'Valid twitter not saved'
    partner.update(twitter_handle: 'asdf')
    refute partner.errors.key?(:twitter_handle), 'Valid twitter not saved'
    partner.update(twitter_handle: 'https://twitter.com/asdf')
    assert partner.errors.key?(:twitter_handle), 'Should be account name not full URL'
    partner.update(twitter_handle: 'asd£$%dsa')
    assert partner.errors.key?(:twitter_handle), 'Invalid Twitter account name saved'
  end

  test 'validate facebook' do
    partner = Partner.new
    # Facebook must be valid
    partner.update(facebook_link: 'https://facebook.com/group-name')
    assert partner.errors.key?(:facebook_link), 'Should be page name not full URL'
    partner.update(facebook_link: 'Group-Name')
    assert partner.errors.key?(:facebook_link), 'invalid Facebook page name saved'
    partner.update(facebook_link: 'GroupName')
    refute partner.errors.key?(:facebook_link), 'Valid page name not saved'
  end
end
