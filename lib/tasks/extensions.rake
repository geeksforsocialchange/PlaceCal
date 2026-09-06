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
      original = gemfile.read
      begin
        bumped = PlaceCal::ExtensionRelease.bump(original, name, version)
      rescue ArgumentError => e
        abort "placecal:extension:bump: #{e.message}"
      end

      if bumped == original
        puts "#{name} is already at #{PlaceCal::ExtensionRelease.normalize_version(version)}."
      else
        gemfile.write(bumped)
        puts "Pinned #{name} at #{PlaceCal::ExtensionRelease.normalize_version(version)} in #{gemfile}."
      end

      # Only this gem's entry moves: a full `bundle install` here would also
      # pick up unrelated updates and put them in the same commit.
      puts "Running bundle lock --update #{name}"
      # Rails has this process bundled already; bundler refuses to re-resolve
      # from inside that environment, so run it in a clean one.
      locked = Bundler.with_unbundled_env { system('bundle', 'lock', '--update', name) }
      unless locked
        # An unreachable tag, a resolution conflict or a dropped network leaves
        # a bumped Gemfile beside a stale Gemfile.lock, which is exactly the
        # pair this task's closing line says must be committed together. Put
        # the Gemfile back so the working tree matches the lock again.
        gemfile.write(original)
        abort "placecal:extension:bump: bundle lock failed. #{gemfile} has been put back as it was."
      end

      puts 'Done. Commit the Gemfile and Gemfile.lock together: that is the deploy.'
    end
  end
end
