# frozen_string_literal: true

namespace :doc do
  desc 'Runs rdoc, outputs to doc/rdoc'
  task generate: :environment do
    app_dirs = 'app/ config/ test/ lib/'
    output_dir = Rails.root.join('doc/rdoc')
    puts "Generating documentation in #{output_dir}"
    command = "rdoc --op #{output_dir} #{app_dirs}"
    # puts "system '#{command}'"
    system command
  end
end
