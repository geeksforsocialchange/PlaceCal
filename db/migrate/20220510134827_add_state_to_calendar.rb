class AddStateToCalendar < ActiveRecord::Migration[6.1]
  def change
    add_column :calendars, :calendar_state, :string, default: 'idle'
  end
end
