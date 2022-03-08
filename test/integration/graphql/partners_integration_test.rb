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
          contactInfo {
            name
            phone
            email
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)

    data = result['data']
    assert data.has_key?('partner')

    data_partner = data['partner']
    assert data_partner.has_key?('contactInfo')

    contact_data = data_partner['contactInfo']
    assert contact_data['name'] == partner.public_name
    assert contact_data['phone'] == partner.public_phone
    assert contact_data['email'] == partner.public_email
  end
end
