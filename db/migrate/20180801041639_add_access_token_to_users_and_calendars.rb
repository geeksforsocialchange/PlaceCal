class AddAccessTokenToUsersAndCalendars < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :access_token, :string
    add_column :users, :access_token_expires_at, :string
    add_column :calendars, :page_access_token, :string
  end
end
