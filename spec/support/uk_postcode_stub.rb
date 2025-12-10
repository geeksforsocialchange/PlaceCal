# frozen_string_literal: true

# Stub UKPostcode to accept Normal Island postcodes in tests
# Normal Island postcodes follow pattern: NO[District] [Ward][Number]
# e.g., NOMB 1RS, NOAD 2VV, NOSV 1CS

# Create a fake postcode class for Normal Island
class NormalIslandPostcode
  PATTERN = /\ANO[A-Z]{2}\s*\d[A-Z]{2}\z/i

  def initialize(postcode)
    @postcode = postcode.to_s.upcase.gsub(/\s+/, ' ')
  end

  def full_valid?
    true
  end

  def valid?
    true
  end

  def to_s
    @postcode
  end
end

# Monkey-patch UKPostcode.parse to handle Normal Island postcodes
module UKPostcodeNormalIslandExtension
  def parse(str)
    normalized = str.to_s.upcase.strip
    if normalized.match?(NormalIslandPostcode::PATTERN)
      NormalIslandPostcode.new(normalized)
    else
      super
    end
  end
end

UKPostcode.singleton_class.prepend(UKPostcodeNormalIslandExtension)
