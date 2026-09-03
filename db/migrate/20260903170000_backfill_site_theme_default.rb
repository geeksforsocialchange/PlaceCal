# frozen_string_literal: true

# Sites carried a nil theme from the enumerize era. The theme registry
# (#3368) treats a blank theme as "no theme", which renders unstyled, so
# backfill the historic default and let the database supply it from now on.
class BackfillSiteThemeDefault < ActiveRecord::Migration[8.0]
  def up
    change_column_default :sites, :theme, 'pink'
    # sites holds a handful of rows, so a single UPDATE is safe here.
    safety_assured do
      execute "UPDATE sites SET theme = 'pink' WHERE theme IS NULL OR theme = ''"
    end
  end

  def down
    change_column_default :sites, :theme, nil
  end
end
