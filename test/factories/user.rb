FactoryBot.define do
  factory(:user) do
    email 'kim@gfsc.studio'
    first_name 'Kim'
    last_name 'Foale'
    password 'password'
    password_confirmation 'password'
  end
end
