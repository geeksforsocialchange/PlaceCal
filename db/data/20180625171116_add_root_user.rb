class AddRootUser < SeedMigration::Migration
  def up
    User.create(
      email: "info@placecal.org",
      password: "password",
      role: :root,
      first_name: "Place",
      last_name: "Cal",
      phone: "0777 7777777"
    )
  end

  def down
    User.destroy_all(email: "info@placecal.org")
  end
end
