# frozen_string_literal: true

class RenamePageAccessTokenToApiToken < ActiveRecord::Migration[8.1]
  def change
    rename_column :calendars, :page_access_token, :api_token
  end
end
