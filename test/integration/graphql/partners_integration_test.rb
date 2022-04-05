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

  def check_address(data, address)
    neighbourhood = address.neighbourhood

    assert_field_equals data, 'streetAddress', value: address.full_street_address
    assert_field_equals data, 'postalCode', value: address.postcode
    assert_field_equals data, 'addressLocality', value: neighbourhood.name
    assert_field_equals data, 'addressRegion', value: neighbourhood.region.to_s

    assert_field data, 'neighbourhood'
    hood = data['neighbourhood']

    assert_field_equals hood, 'name', value: neighbourhood.name
    assert_field_equals hood, 'abbreviatedName', value: neighbourhood.abbreviated_name
    assert_field_equals hood, 'unit', value: neighbourhood.unit
    assert_field_equals hood, 'unitName', value: neighbourhood.unit_name
    assert_field_equals hood, 'unitCodeKey', value: neighbourhood.unit_code_key
    assert_field_equals hood, 'unitCodeValue', value: neighbourhood.unit_code_value
  end

  def check_contact(data, contact)
    assert_field_equals data, 'name', value: contact.public_name

    assert_field_equals data, 'telephone', value: contact.public_phone

    assert_field_equals data, 'email', value: contact.public_email
  end

  def check_opening_hours(data, opening_hours)
    opening_hours = JSON.parse(opening_hours)
    expected_day = opening_hours.first

    assert_kind_of Array, data, 'openingHours should be an array'
    assert data.length == 6 # from factory
    first_day = data.first

    expected_day_of_week = expected_day['dayOfWeek'] =~ %r{/([^/]*)$} && Regexp.last_match(1)
    assert_field_equals first_day, 'dayOfWeek', value: expected_day_of_week

    assert_field_equals first_day, 'opens', value: expected_day['opens']
    assert_field_equals first_day, 'closes', value: expected_day['closes']
  end

  def check_areas_served(data, service_areas)
    assert_kind_of Array, data, 'areasServed should be an array'
    assert data.length == service_areas.count

    wanted_area = service_areas.first
    service_area = data.first

    assert_field_equals service_area, 'name', value: wanted_area.name
    assert_field_equals service_area, 'abbreviatedName', value: wanted_area.abbreviated_name
    assert_field_equals service_area, 'unit', value: wanted_area.unit
    assert_field_equals service_area, 'unitName', value: wanted_area.unit_name
    assert_field_equals service_area, 'unitCodeKey', value: wanted_area.unit_code_key
    assert_field_equals service_area, 'unitCodeValue', value: wanted_area.unit_code_value
  end

  def check_basic_fields(data, partner)
    assert_field_equals data, 'id', value: partner.id.to_s

    assert_field_equals data, 'name', value: partner.name
    assert_field_equals data, 'summary', value: partner.summary
    assert_field_equals data, 'description', value: partner.description
    assert_field_equals data, 'accessibilitySummary', value: partner.accessibility_info
    assert_field_equals data, 'url', value: partner.url
    assert_field_equals data, 'twitterUrl', value: "https://twitter.com/#{partner.twitter_handle}"
    assert_field_equals data, 'facebookUrl', value: partner.facebook_link

    # see note below
    # assert_field_equals data, 'logo', value: partner.image.url
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

    assert_field data, 'partner'
    partner_data = data['partner']

    check_basic_fields partner_data, partner

    assert_field partner_data, 'address'
    check_address partner_data['address'], partner.address

    assert_field partner_data, 'contact'
    check_contact partner_data['contact'], partner

    assert_field partner_data, 'openingHours'
    check_opening_hours partner_data['openingHours'], partner.opening_times

    assert_field partner_data, 'areasServed'
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
