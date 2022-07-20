class RemoveCalendarContactInfoFields < ActiveRecord::Migration[6.1]
  def change
    remove_column :calendars, :partnership_contact_name, :string
    remove_column :calendars, :partnership_contact_email, :string
    remove_column :calendars, :partnership_contact_phone, :string
  end
end
