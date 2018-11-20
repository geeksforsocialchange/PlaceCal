module Placecal
  module Entities
    class Event < Grape::Entity
      expose :context, as: '@context'
      expose :type, as: '@type'
      expose :summary, as: 'name'
      expose :dtstart, as: 'startDate'
      expose :dtend, as: 'endDate'
      expose :duration, if: ->(object) { object.duration }
      expose :description
      expose :place do
        expose :place_type, as: '@type'
        expose :place_name, as: 'name', if: ->(object) { object.place }
        expose :address, using: Placecal::Entities::Address
      end
      expose :permalink, as: 'url'

      private

      def context
        'http://schema.org'
      end

      def type
        'Event'
      end

      def place_type
        'Place'
      end

      def place_name
        object.place.name
      end
    end
  end
end
