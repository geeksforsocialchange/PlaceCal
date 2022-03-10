module Types
  class ContactType < Types::BaseObject

    description ''

    field :name, String, null: false, method: :public_name
    field :email, String, null: false, method: :public_email
    field :telephone, String, null: false, method: :public_phone

  end
end

