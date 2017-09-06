class Calendar < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :partner
  belongs_to :place

  extend Enumerize

  enumerize :type, in: [:facebook, :google, :outlook, :mac_calendar, :other], default: :other
end
