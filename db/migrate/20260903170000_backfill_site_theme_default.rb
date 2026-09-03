# frozen_string_literal: true

# Sites gained a contact email for their own enquiries (#3368), and carried a
# nil theme from the enumerize era. The theme registry treats a blank theme as
# "no theme", which renders unstyled, so backfill the historic default and let
# the database supply it from now on.
class BackfillSiteThemeDefault < ActiveRecord::Migration[8.0]
  def up
    add_column :sites, :contact_email, :string
    change_column_default :sites, :theme, 'pink'
    # sites holds a handful of rows, so a single UPDATE is safe here.
    safety_assured do
      execute "UPDATE sites SET theme = 'pink' WHERE theme IS NULL OR theme = ''"
    end
  end

  def down
    remove_column :sites, :contact_email
    change_column_default :sites, :theme, nil
  end
end
