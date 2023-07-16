# frozen_string_literal: true

module SeedSanityCheck
  FAIL_CODE = -1

  MODELS = [
    Neighbourhood,
    Calendar,
    User,
    Partner,
    Event
  ].freeze

  def self.run
    $stdout.puts 'Sanity test'

    MODELS.each do |model|
      next if model.count.zero?

      warn '  you have data in your DB!'
      exit FAIL_CODE
    end

    $stdout.puts '  passed.'
  end
end

SeedSanityCheck.run
