class AddDeviseInvitable < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :invitation_token, :string
    add_column :users, :invitation_created_at, :datetime
    add_column :users, :invitation_sent_at, :datetime
    add_column :users, :invitation_accepted_at, :datetime
    add_column :users, :invitation_limit, :integer
    add_column :users, :invited_by_id, :integer
    add_column :users, :invited_by_type, :string
    add_index :users, :invitation_token, unique: true

    # Allow null encrypted_password
    change_column_null :users, :encrypted_password, :string, true
    # Allow null password_salt (add it if you are using Devise's encryptable module)
    # change_column_null :users, :password_salt, :string, true
  end
end
