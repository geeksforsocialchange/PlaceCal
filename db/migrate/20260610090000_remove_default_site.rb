# frozen_string_literal: true

# The nationwide directory is no longer backed by a magic 'default-site' Site
# row: an apex request with no matching site now renders the directory. Remove
# the legacy row (destroy! so dependent join rows and callbacks run).
class RemoveDefaultSite < ActiveRecord::Migration[8.0]
  def up
    Site.find_by(slug: 'default-site')&.destroy!
  end

  def down
    # Irreversible by design: the row is gone and nothing references it.
  end
end
