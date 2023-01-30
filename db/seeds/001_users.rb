
module UserSeeder
  extend self

  def run
    user = User.find_or_create_by!(email: "admin@lvh.me") do |user|
      user.password = "password"
      user.password_confirmation = "password"
    end
    user.update! role: :root
    user.accept_invitation!
  end
end

UserSeeder.run
