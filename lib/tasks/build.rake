# frozen_string_literal: true

namespace :assets do
  desc 'Build Tailwind CSS before assets:precompile'
  task build_css: :environment do
    puts 'Building Tailwind CSS...'
    system('yarn css-admin') || abort('Tailwind CSS build failed')
  end
end

# Ensure CSS is built before assets are precompiled
Rake::Task['assets:precompile'].enhance(['assets:build_css']) if Rake::Task.task_defined?('assets:precompile')
