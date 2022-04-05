# frozen_string_literal: true

require 'test_helper'

class GraphQLPartnerTest < ActionDispatch::IntegrationTest
  test 'can show partners' do
    5.times do |n|
      FactoryBot.create(:partner, name: "Partner #{n}")
    end

    query_string = <<-GRAPHQL
      query {
        partnerConnection {
          edges {
            node {
              id
              summary
              description
            }
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    data = result['data']

    assert data.key?('partnerConnection'), 'result is missing key `partnerConnection`'
    connection = data['partnerConnection']

    assert connection.key?('edges')
    edges = connection['edges']

    assert edges.length == 5
  end

  test 'can show specific partner' do
    partner = FactoryBot.create(:partner)

    query_string = <<-GRAPHQL
      query {
        partner(id: #{partner.id}) {
          id
          name
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)

    data = result['data']
    assert data.key?('partner')

    data_partner = data['partner']
    assert data_partner['name'] == partner.name

  end

  def verify_field_presence(obj, name, value: nil)
    assert obj.key?(name), "field #{name} is missing"
    if value
      assert_equal value, obj[name], "field #{name} has incorrect value: wanted='#{value}', but got='#{obj[name]}'"
    end

  rescue Minitest::Assertion => e
    # ugh- we need to see the line that actually caused the problem here and not
    # just the above assertion line
    puts e.backtrace[2]
    raise e
  end

  def check_address(data, address)
    neighbourhood = address.neighbourhood

    verify_field_presence data, 'streetAddress', value: address.full_street_address
    verify_field_presence data, 'postalCode', value: address.postcode
    verify_field_presence data, 'addressLocality', value: neighbourhood.name
    verify_field_presence data, 'addressRegion', value: neighbourhood.region.to_s

    verify_field_presence data, 'neighbourhood'
    hood = data['neighbourhood']

    verify_field_presence hood, 'name', value: neighbourhood.name
    verify_field_presence hood, 'abbreviatedName', value: neighbourhood.abbreviated_name
    verify_field_presence hood, 'unit', value: neighbourhood.unit
    verify_field_presence hood, 'unitName', value: neighbourhood.unit_name
    verify_field_presence hood, 'unitCodeKey', value: neighbourhood.unit_code_key
    verify_field_presence hood, 'unitCodeValue', value: neighbourhood.unit_code_value
  end

  def check_contact(data, contact)
    verify_field_presence data, 'name', value: contact.public_name

    verify_field_presence data, 'telephone', value: contact.public_phone

    verify_field_presence data, 'email', value: contact.public_email
  end

  def check_opening_hours(data, opening_hours)
    opening_hours = JSON.parse(opening_hours)
    expected_day = opening_hours.first

    assert_kind_of Array, data, 'openingHours should be an array'
    assert data.length == 6 # from factory
    first_day = data.first

    expected_day_of_week = expected_day['dayOfWeek'] =~ /\/([^\/]*)$/ && $1
    verify_field_presence first_day, 'dayOfWeek', value: expected_day_of_week

    verify_field_presence first_day, 'opens', value: expected_day['opens']
    verify_field_presence first_day, 'closes', value: expected_day['closes']
  end

  def check_areas_served(data, service_areas)
    assert_kind_of Array, data, 'areasServed should be an array'
    assert data.length == service_areas.count

    wanted_area = service_areas.first
    service_area = data.first

    verify_field_presence service_area, 'name', value: wanted_area.name
    verify_field_presence service_area, 'abbreviatedName', value: wanted_area.abbreviated_name
    verify_field_presence service_area, 'unit', value: wanted_area.unit
    verify_field_presence service_area, 'unitName', value: wanted_area.unit_name
    verify_field_presence service_area, 'unitCodeKey', value: wanted_area.unit_code_key
    verify_field_presence service_area, 'unitCodeValue', value: wanted_area.unit_code_value
  end

  def check_basic_fields(data, partner)
    verify_field_presence data, 'id', value: partner.id.to_s
    verify_field_presence data, 'name', value: partner.name
    verify_field_presence data, 'summary', value: partner.summary
    verify_field_presence data, 'description', value: partner.description
    verify_field_presence data, 'accessibilitySummary', value: partner.accessibility_info
    verify_field_presence data, 'url', value: partner.url
    verify_field_presence data, 'twitterUrl', value: "https://twitter.com/#{partner.twitter_handle}"
    verify_field_presence data, 'facebookUrl', value: partner.facebook_link

    # see note below
    # verify_field_presence data, 'logo', value: partner.image.url
  end

  test 'can view contact info when selected' do
    partner = FactoryBot.create(:partner, twitter_handle: 'Alpha', image: 'https://example.com/logo.png')
    partner.service_area_neighbourhoods << neighbourhoods(:one)

    # FIXME: logo URL field is tricky as it expects an upload from rails
    #   which would require a fixture file. also not sure how this works
    #   on a production environment because of how the URL is generated
    #   using the rails application domain (in theory). -IK

    query_string = <<-GRAPHQL
      query {
        partner(id: #{partner.id}) {
          id
          name
          summary
          description
          accessibilitySummary
          logo
          url
          facebookUrl
          twitterUrl

          address {
            streetAddress
            postalCode
            addressLocality
            addressRegion
            neighbourhood {
              name
              abbreviatedName
              unit
              unitName
              unitCodeKey
              unitCodeValue
              }
          }

          contact {
            name
            email
            telephone
          }
          openingHours {
            dayOfWeek
            opens
            closes
          }
          areasServed {
            name
            abbreviatedName
            unit
            unitName
            unitCodeKey
            unitCodeValue
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute result.key?('errors'), 'errors are present'

    data = result['data']

    verify_field_presence data, 'partner'
    partner_data = data['partner']

    check_basic_fields partner_data, partner

    verify_field_presence partner_data, 'address'
    check_address partner_data['address'], partner.address

    verify_field_presence partner_data, 'contact'
    check_contact partner_data['contact'], partner

    verify_field_presence partner_data, 'openingHours'
    check_opening_hours partner_data['openingHours'], partner.opening_times

    verify_field_presence partner_data, 'areasServed'
    check_areas_served partner_data['areasServed'], partner.service_area_neighbourhoods
  end

  test 'can see published articles by partnetr' do
    user = create(:user)
    partner = FactoryBot.create(:partner, twitter_handle: 'Alpha')

    article_1 = partner.articles.create!(
      title: 'A published article',
      author: user,
      body: 'This article has been published',
      is_draft: false,
      published_at: Date.today
    )

    article_2 = partner.articles.create!(
      title: 'An article that is not published',
      author: user,
      body: 'This article has not been published',
      is_draft: true,
      published_at: nil
    )

    query_string = <<-GRAPHQL
      query {
        partner(id: #{partner.id}) {
          articles {
            headline
            articleBody
            datePublished
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute result.key?('errors'), 'errors are present'

    data = result['data']
    partner_data = data['partner']
    article_data = partner_data['articles']

    assert article_data.length == 1, 'Should only see the one article published by this partenr'
  end

  test 'finding partners by tag' do
    partner = FactoryBot.create(:partner)
    tag = FactoryBot.create(:tag)
    partner.tags << tag

    query_string = <<-GRAPHQL
      query {
        partnersByTag(tagId: #{tag.id}) {
          name
          description
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute result.key?('errors'), 'errors are present'

    data = result['data']
    partner_data = data['partnersByTag']
    assert partner_data.length == 1, 'expecting to see a tag on this partner'
  end

  test 'returns null properly if openning times are missing' do
    partner = FactoryBot.create(:partner, opening_times: nil)

    query_string = <<-GRAPHQL
      query {
        partner(id: #{partner.id}) {
          openingHours {
            opens
            closes
            dayOfWeek
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    assert result.key?('errors') == false, 'errors are present'

    data = result['data']
    assert data.key?('partner')

    data_partner = data['partner']
    assert data_partner.key?('openingHours')

    opening_hours = data_partner['openingHours']
    assert_nil opening_hours
  end

end
