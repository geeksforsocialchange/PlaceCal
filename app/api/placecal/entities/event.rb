module Placecal
  module Entities
    class Event < Grape::Entity
      expose :summary, as: 'name'
      expose :dtstart, as: 'startDate'
      expose :dtend, as: 'endDate'
      expose :description
      expose :location
      expose :permalink, as: 'url'
    end
  end
end
