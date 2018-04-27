namespace :fixes do
  task rename_admins_to_root: :environment do
    User.update_all(role: 'root')
  end
end
