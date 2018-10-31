class ChangeCalendarContactDetailsToTypeString < ActiveRecord::Migration[5.1]
  def change
    change_column :calendars, :partnership_contact_name, :string
    change_column :calendars, :partnership_contact_email, :string
    change_column :calendars, :partnership_contact_phone, :string
    change_column :calendars, :public_contact_name, :string
    change_column :calendars, :public_contact_email, :string
    change_column :calendars, :public_contact_phone, :string
  end
end
