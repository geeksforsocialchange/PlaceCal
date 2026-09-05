# frozen_string_literal: true

require_relative '../placecal/extension_release'

namespace :placecal do
  namespace :extension do
    desc 'Bump an extension to a released tag and relock: ' \
         'rake "placecal:extension:bump[placecal-theme-mossley,0.1.2]"'
    task :bump, %i[name version] => :environment do |_task, args|
      name = args[:name]
      version = args[:version]
      abort 'Usage: rake "placecal:extension:bump[<gem>,<version>]"' if name.blank? || version.blank?

      gemfile = Rails.root.join('Gemfile')
      begin
        bumped = PlaceCal::ExtensionRelease.bump(gemfile.read, name, version)
      rescue ArgumentError => e
        abort "placecal:extension:bump: #{e.message}"
      end

      if bumped == gemfile.read
        puts "#{name} is already at #{PlaceCal::ExtensionRelease.normalize_version(version)}."
      else
        gemfile.write(bumped)
        puts "Pinned #{name} at #{PlaceCal::ExtensionRelease.normalize_version(version)} in #{gemfile}."
      end

      # Only this gem's entry moves: a full `bundle install` here would also
      # pick up unrelated updates and put them in the same commit.
      puts "Running bundle lock --update #{name}"
      abort 'placecal:extension:bump: bundle lock failed.' unless system('bundle', 'lock', '--update', name)

      puts 'Done. Commit the Gemfile and Gemfile.lock together: that is the deploy.'
    end
  end
end
