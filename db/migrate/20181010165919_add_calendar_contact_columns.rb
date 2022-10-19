# frozen_string_literal: true

class AddCalendarContactColumns < ActiveRecord::Migration[5.1]
  def change
    # NOTE: Not copying any data over from partners. Staging server had no
    # relevant data to copy. Assuming production the same
    change_table :calendars do |t|
      t.text :partnership_contact_name
      t.text :partnership_contact_email
      t.text :partnership_contact_phone
      t.text :public_contact_name
      t.text :public_contact_email
      t.text :public_contact_phone
    end
  end
end
