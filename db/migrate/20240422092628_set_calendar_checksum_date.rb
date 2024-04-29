# frozen_string_literal: true

class SetCalendarChecksumDate < ActiveRecord::Migration[7.1]
  def change
    Calendar.update_all('checksum_updated_at=last_import_at')
  end
end
