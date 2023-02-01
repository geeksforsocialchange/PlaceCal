# frozen_string_literal: true

module UserSeeder
  module_function

  def run
    user = User.find_or_create_by!(email: 'admin@lvh.me') do |u|
      u.password = 'password'
      u.password_confirmation = 'password'
      u.role = :root
    end

    user.invite!
    user.accept_invitation!
  end
end

UserSeeder.run
