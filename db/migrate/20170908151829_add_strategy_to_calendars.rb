class AddStrategyToCalendars < ActiveRecord::Migration[5.1]
  def change
    add_column :calendars, :strategy, :string
  end
end
