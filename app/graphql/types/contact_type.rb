module Types
  class ContactType < Types::BaseObject
    description 'Contact information for a person or venue'

    field :name, String,
          null: false,
          method: :public_name,
          description: 'Name of contact'

    field :email, String,
          null: false,
          method: :public_email,
          description: 'Email address of contact'

    field :telephone, String,
          null: false,
          method: :public_phone,
          description: 'Telephone number of contact'
  end
end
