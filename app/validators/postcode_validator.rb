# frozen_string_literal: true

class PostcodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    ukpc = UKPostcode.parse(value)

    record.errors.add(attribute, 'not recognised as a UK postcode') unless ukpc.full_valid?
  end
end
