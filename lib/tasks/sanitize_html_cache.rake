# frozen_string_literal: true

namespace :html_cache do
  desc 'Re-render and sanitize all cached HTML fields (run after adding sanitization)'
  task sanitize: :environment do
    [Partner, Event, Article, Site].each do |klass|
      count = klass.count
      puts "Processing #{count} #{klass.name} records..."

      klass.find_each.with_index do |record, i|
        record.force_html_generation!
        record.save!(validate: false)
        print '.' if ((i + 1) % 100).zero?
      end

      puts "\n  Done: #{count} #{klass.name} records sanitized."
    end
  end
end
