User.find_or_create_by!(
  email: "admin@lvh.me"
) do |user|
  user.password = "password"
  user.password_confirmation = "password"
end.update!(
  role: :root
)
