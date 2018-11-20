module Placecal
  module Entities
    class Address < Grape::Entity
      expose :type, as: '@type'
      expose :full_street_address, as: 'streetAddress'
      expose :city, as: 'addressRegion'
      expose :postcode, as: 'postalCode'

      private

      def type
        'PostalAddress'
      end
    end
  end
end
