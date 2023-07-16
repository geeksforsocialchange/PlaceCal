# frozen_string_literal: true

module SeedUsers
  # role: root, editor, citizen

  USER_INFO = [
    {
      first_name: 'root',
      last_name: 'placecal',
      role: 'root',
      phone: '301-688-6311',
      email: 'root@placecal.org'
    },
    {
      first_name: 'editor',
      last_name: 'placecal',
      role: 'editor',
      phone: '301-688-6311',
      email: 'editor@placecal.org'
    },
    {
      first_name: 'citizen',
      last_name: 'placecal',
      role: 'citizen',
      phone: '301-688-6311',
      email: 'citizen@placecal.org'
    }
  ].freeze

  def self.run
    $stdout.puts 'Users'

    USER_INFO.each do |user_info|
      user = User.create!(
        user_info.merge(
          password: 'password',
          password_confirmation: 'password'
        )
      )

      user.skip_invitation = true
      user.invite!
      user.accept_invitation!
    end
  end
end

SeedUsers.run
