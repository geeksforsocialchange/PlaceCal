# frozen_string_literal: true

# lib/tasks/yard.rake
desc 'Generate code documentation with YARD'
task yard: [] do
  YARD::Rake::YardocTask.new do |t|
    t.files = %w[lib/**/*.rb app/**/*.rb - doc/adr/*.md INSTALL.md README.md]
    # t.options = %w[-r]
  end
end
