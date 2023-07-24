# frozen_string_literal: true

module SeedSanityCheck
  FAIL_CODE = -1

  MODELS = [
    Neighbourhood,
    Calendar,
    User,
    Partner,
    Event,
    Site,
    Article,
    Tag
  ].freeze

  def self.run
    $stdout.puts 'Sanity test'

    MODELS.each do |model|
      count = model.count
      next if count.zero?

      warn "  you have data in your DB! (#{model.name}=#{count})"
      exit FAIL_CODE
    end

    $stdout.puts '  passed.'
  end
end

SeedSanityCheck.run
