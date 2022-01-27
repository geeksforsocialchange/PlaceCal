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


class PartnerServiceAreaTest < ActiveSupport::TestCase
  setup do
    @partner = create(:partner)
    @neighbourhood = create(:neighbourhood)
  end

  test 'is valid when empty' do
    assert @partner.valid?, 'Partner (without service_area) is not valid'
  end

  test 'is valid when set, can be accessed' do
    model = build(:ashton_service_area_partner)
    model.save!
    assert model.valid?

    service_areas = model.service_areas
    assert_equal 1, service_areas.count
  end

  test 'can be assigned' do
    @partner.service_areas.create(neighbourhood: @neighbourhood)
    assert @partner.valid?, 'Partner (with service_area) is not valid'

    neighbourhood_count = @partner.service_area_neighbourhoods.count
    assert_equal 1, neighbourhood_count, 'count neighbourhoods'
  end

  test 'must be unique' do
    assert_raises ActiveRecord::RecordInvalid do 
      @partner.service_areas.create!(neighbourhood: @neighbourhood)
      @partner.service_areas.create!(neighbourhood: @neighbourhood)
    end
    # need to also test this with regards to model creation from the web front-end
  end

  test 'can be read when present' do
    other_neighbourhood = create(:ashton_neighbourhood)

    @partner.service_areas.create! neighbourhood: @neighbourhood
    @partner.service_areas.create! neighbourhood: other_neighbourhood

    neighbourhoods = @partner.service_area_neighbourhoods.order('neighbourhoods.name').all
    assert neighbourhoods.count == 2, 'Failed to count neighbourhoods'

    n1 = neighbourhoods[0]
    assert_equal 'Ashton Hurst', n1.name

    n2 = neighbourhoods[1]
    assert_equal 'Hulme Longname', n2.name
  end

end
