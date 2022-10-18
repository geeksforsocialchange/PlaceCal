# frozen_string_literal: true

require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @new_address = create(:address)
    @new_partner = build(:partner, address: @new_address, accessed_by_user: @user)
  end

  test 'updates user roles when saved' do
    @new_partner.users << @user
    @new_partner.save
    assert_predicate @user, :partner_admin?
  end

  test 'can change postcode of partner' do
    @new_partner.save!

    new_postcode = 'OL6 8BH'
    new_params = {
      address_attributes: {
        street_address: @new_address.street_address,
        postcode: new_postcode
      }
    }

    @new_partner.update! new_params
    @new_partner.reload

    assert_equal @new_partner.address.postcode, new_postcode
  end

  test 'it recycles addresses if it can' do
    @new_partner.save!

    other_partner = build(:partner, address: nil, accessed_by_user: @user)
    other_params = {
      address_attributes: {
        street_address: @new_address.street_address,
        postcode: @new_address.postcode
      }
    }
    other_partner.update! other_params
    other_partner.reload

    assert_equal @new_partner.address_id, other_partner.address_id, 'should have same address ID'
  end

  test 'validate name length' do
    @new_partner.update(name: '1234')

    assert error_map = @new_partner.errors.where(:name, :too_short).first
    assert_equal 'must be at least 5 characters long', error_map.options[:message]
    assert_equal 1, @new_partner.errors.attribute_names.length
  end

  test 'validate uniqueness' do
    other_partner = Partner.create(name: 'Alpha Name', address: @new_partner.address, accessed_by_user: @user)

    # Name must be unique
    @new_partner.update(name: other_partner.name)
    assert_equal ['has already been taken'], @new_partner.errors[:name]
  end

  test 'validate no summary or description' do
    @new_partner.update(name: 'Test Partner', summary: '', description: '')
    assert_empty @new_partner.errors
  end

  test 'validate summary without description' do
    @new_partner.update(name: 'Test Partner', summary: 'This is a test partner used for testing :)', description: '')
    assert_empty @new_partner.errors, 'Should be able to submit a summary'
  end

  test 'validate description without summary' do
    @new_partner.update(
      name: 'Test Partner',
      description: 'This is a test partner used for testing :)',
      summary: ''
    )
    assert_equal ['cannot have a description without a summary'],
                 @new_partner.errors[:summary],
                 'Should not be able to have a description without summary'
  end

  test 'validate description and summary' do
    @new_partner.update(name: 'Test Partner',
                        summary: 'This is a test summary wheee :)',
                        description: 'This is a test new_partner used for testing :)')
    assert_empty @new_partner.errors, 'Should be able to submit a summary and description'
  end

  test 'validate summary length' do
    # We can submit a 200 character summary
    @new_partner.update(name: 'Test Partner', summary: ''.ljust(200, 'a'))
    assert_empty @new_partner.errors, '200 character summary should be valid'

    # But not a 201 character summary
    @new_partner.update(name: 'Test Partner', summary: ''.ljust(201, 'a'))
    assert @new_partner.errors.key?(:summary), 'maximum length is 200 characters'
  end

  test 'validate url' do
    # Url must be valid
    @new_partner.update(url: 'htp://bad-domain.co')
    assert_equal ['is invalid'], @new_partner.errors[:url], 'Partner must have a valid url'
    @new_partner.update(url: 'https://good-domain.com')
    assert_not @new_partner.errors.key?(:url), 'Valid URL not saved'
  end

  test 'validate twitter' do
    # Twitter must be valid
    @new_partner.update(twitter_handle: '@asdf')
    assert_not @new_partner.errors.key?(:twitter_handle), 'Valid twitter not saved'
    @new_partner.update(twitter_handle: 'asdf')
    assert_not @new_partner.errors.key?(:twitter_handle), 'Valid twitter not saved'
    @new_partner.update(twitter_handle: 'https://twitter.com/asdf')
    assert @new_partner.errors.key?(:twitter_handle), 'Should be account name not full URL'
    @new_partner.update(twitter_handle: 'asd£$%dsa')
    assert @new_partner.errors.key?(:twitter_handle), 'Invalid Twitter account name saved'
  end

  test 'validate facebook' do
    # Facebook must be valid
    @new_partner.update(facebook_link: 'https://facebook.com/group-name')
    assert @new_partner.errors.key?(:facebook_link), 'Should be page name not full URL'
    @new_partner.update(facebook_link: 'Group-Name')
    assert @new_partner.errors.key?(:facebook_link), 'invalid Facebook page name saved'
    @new_partner.update(facebook_link: 'GroupName')
    assert_not @new_partner.errors.key?(:facebook_link), 'Valid page name not saved'
  end

  test 'deals with badly formatted opening times' do
    partner = build(:partner)
    partner.opening_times = '{{ $data.openingHoursSpecifications }}'

    assert_empty partner.human_readable_opening_times
  end

  test 'opening_times can be unset' do
    p = Partner.new
    assert_equal '[]', p.opening_times_data

    p = Partner.new opening_times: ''
    assert_equal '[]', p.opening_times_data

    opening_times_payload = [
      { opens: '', closes: '' },
      { opens: '', closes: '' },
      { opens: '', closes: '' }
    ].to_json

    p = Partner.new(opening_times: opening_times_payload)

    found = JSON.parse(p.opening_times_data)
    assert_equal 3, found.length
  end
end
