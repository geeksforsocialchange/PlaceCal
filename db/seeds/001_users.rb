# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedUsers
  def self.run
    $stdout.puts 'Users'

    # Root admin
    User.create!(
      email: NormalIsland::USERS[:root_admin][:email],
      password: 'password',
      password_confirmation: 'password',
      first_name: NormalIsland::USERS[:root_admin][:first_name],
      last_name: NormalIsland::USERS[:root_admin][:last_name],
      role: NormalIsland::USERS[:root_admin][:role]
    )

    $stdout.puts "  Created admin user: #{NormalIsland::USERS[:root_admin][:email]}"
  end
end

SeedUsers.run
