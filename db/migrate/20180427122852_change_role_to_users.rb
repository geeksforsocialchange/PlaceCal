# frozen_string_literal: true

class ChangeRoleToUsers < ActiveRecord::Migration[5.1]
  def change
    users = User.where(role: %w[admin secretary])
    users.find_each do |user|
      user.role = "root"
      user.save!
    end
  end
end
