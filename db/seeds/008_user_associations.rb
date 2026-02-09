# frozen_string_literal: true

# Assign admin associations to users now that partners, sites, and neighbourhoods exist
$stdout.puts 'User associations'
SeedUsers.assign_associations
