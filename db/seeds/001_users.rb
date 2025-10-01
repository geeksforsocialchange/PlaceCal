# frozen_string_literal: true

module SeedUsers
  def self.run
    $stdout.puts 'Users'

    User.create!(
      email: 'info@placecal.org',
      password: 'password',
      password_confirmation: 'password',
      first_name: 'default',
      last_name: 'admin',
      role: :root
    )
  end
end

SeedUsers.run
