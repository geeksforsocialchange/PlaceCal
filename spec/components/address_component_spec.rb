# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddressComponent, type: :component do
  let(:address) { create(:riverside_address) }
  let(:raw_location) { 'Unformatted Address, Ungeolocated Lane' }

  it 'renders address information' do
    render_inline(described_class.new(address: address, raw_location: raw_location))

    expect(page).to have_text(address.street_address)
    expect(page).to have_text(address.postcode)
  end

  it 'renders with just an address' do
    render_inline(described_class.new(address: address, raw_location: nil))

    expect(page).to have_text(address.street_address)
  end

  it 'renders with raw location when no address' do
    render_inline(described_class.new(address: nil, raw_location: raw_location))

    expect(page).to have_text(raw_location)
  end
end
