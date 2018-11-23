module Placecal
  module Entities
    class Event < Grape::Entity
      expose :context, as: '@context'
      expose :type, as: '@type'
      expose :summary, as: 'name'
      expose :dtstart, as: 'startDate'
      expose :dtend, as: 'endDate', expose_nil: false
      expose :duration, expose_nil: false
      expose :description, expose_nil: false

      expose :partner, as: 'organizer', if: ->(obj) { obj&.partner } do
        expose :partner_type, as: '@type'
        expose :partner_name, as: 'name'
        expose :partner_url, as: 'url'
      end

      expose :place, as: 'location' do
        expose :place_type, as: '@type'
        expose :place_name, as: 'name', if: ->(obj) { obj.place }
        expose :place_phone, as: 'telephone', if: ->(obj) { obj.place&.partner_phone }
        expose :address, using: Placecal::Entities::Address
        expose :place_url, as: 'url', if: ->(obj) { obj.place }
      end

      expose :permalink, as: 'url'

      private

      def context
        'https://schema.org'
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

      def place_phone
        object.place.partner_phone
      end

      def place_url
        object.place.permalink
      end

      def partner_type
        'Organization'
      end

      def partner_name
        object.partner.name
      end

      def partner_url
        object.partner.permalink
      end

    end
  end
end
