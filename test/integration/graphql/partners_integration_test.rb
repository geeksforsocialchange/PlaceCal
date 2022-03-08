# frozen_string_literal: true

require 'test_helper'

class GraphQLPartnerTest < ActionDispatch::IntegrationTest
  test 'can show partners' do
    5.times do |n|
      FactoryBot.create(:partner, name: "Partner #{n}")
    end

    query_string = <<-GRAPHQL
      query {
        allPartners {
          id
          name
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    data = result['data']
    assert data.has_key?('allPartners')

    partners = data['allPartners']
    assert partners.length == 5
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
    assert data.has_key?('partner')

    data_partner = data['partner']
    assert data_partner['name'] == partner.name

  end

  test 'can view contact info when selected' do

    partner = FactoryBot.create(:partner)

    query_string = <<-GRAPHQL
      query {
        partner(id: #{partner.id}) {
          id
          name
          contactName
          telephone
          email
          twitter
          url
          facebook
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)

    data = result['data']
    assert data.has_key?('partner')

    data_partner = data['partner']
    assert data_partner.has_key?('contactName')
    assert data_partner['contactName'] == partner.public_name

    assert data_partner.has_key?('telephone')
    assert data_partner['telephone'] == partner.public_phone

    assert data_partner.has_key?('email')
    assert data_partner['email'] == partner.public_email
    
    assert data_partner.has_key?('url')
    assert data_partner['url'] == partner.url
    
    assert data_partner.has_key?('twitter')
    assert data_partner['twitter'] == partner.twitter_handle
    
    assert data_partner.has_key?('facebook')
    assert data_partner['facebook'] == partner.facebook_link

  end
end
