# frozen_string_literal: true

class RenameTurvesToTurfs < ActiveRecord::Migration[5.1]
  def change
    rename_table :turves, :turfs
    rename_table :turves_users, :turfs_users
    rename_table :partners_turves, :partners_turfs
  end
end
