class Supporter < ApplicationRecord
  has_and_belongs_to_many :sites
end
