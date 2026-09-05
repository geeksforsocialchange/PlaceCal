# frozen_string_literal: true

# The Mossley site was on core's legacy per-site `custom` theme, which resolved
# its stylesheet and map style from the site slug. That theme is gone: Mossley
# is an extension (placecal-theme-mossley) registering a theme named after
# itself, so the row has to name it.
#
# Mossley is the only site that ever used `custom`, so this is one row on one
# small table. Raw SQL rather than the Site model: a migration outlives the
# model's validations, and `theme` is validated against the extension registry,
# which is not something a migration should have to satisfy.
#
# safety_assured because strong_migrations cannot see inside `execute`. This is
# a single-column UPDATE on `sites`, which holds a handful of rows and is not
# written to during a deploy, so it takes a row lock for microseconds.
class MoveMossleyToTheExtensionTheme < ActiveRecord::Migration[8.0]
  def up
    safety_assured { execute("UPDATE sites SET theme = 'mossley' WHERE theme = 'custom'") }
  end

  def down
    safety_assured { execute("UPDATE sites SET theme = 'custom' WHERE theme = 'mossley'") }
  end
end
