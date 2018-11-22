module Placecal
  module Entities
    class Address < Grape::Entity
      expose :type, as: '@type'
      expose :full_street_address, as: 'streetAddress'
      expose :region, as: 'addressRegion'
      expose :postcode, as: 'postalCode'

      private

      def type
        'PostalAddress'
      end

      def region
        object.last_line_of_address
      end
    end
  end
end
