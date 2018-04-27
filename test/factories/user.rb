FactoryBot.define do
  factory(:user) do
    sequence :email do |n|
      "test+#{n}@placecal.org"
    end
    first_name 'Kim'
    last_name 'Foale'
    password 'password'
    password_confirmation 'password'

    factory(:admin) do
      role 'secretary'
    end

    factory(:root) do
      role 'root'
    end
  end
end
