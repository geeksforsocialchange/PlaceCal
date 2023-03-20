# frozen_string_literal: true

namespace :fixes do
  desc 'updates malformed opening_times data'
  task reset_bad_opening_times: :environment do
    bad_partners = Partner.where(opening_times: '{{ $data.openingHoursSpecifications }}')
    $stdout.puts "Found #{bad_partners.count} partners with opening_times that are not valid JSON"
    bad_partners.each do |partner|
      partner.opening_times = '[]'
      partner.save!
    end
  end
end
