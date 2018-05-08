class SitesTurf < ApplicationRecord
  self.table_name = 'sites_turfs'
  belongs_to :turf
  belongs_to :site
end

