# frozen_string_literal: true

module Types
  class ContactType < Types::BaseObject
    description 'Contact information for a person or venue'

    field :name, String,
          method: :public_name,
          description: 'Name of contact'

    field :email, String,
          method: :public_email,
          description: 'Email address of contact'

    field :telephone, String,
          method: :public_phone,
          description: 'Telephone number of contact'
  end
end
