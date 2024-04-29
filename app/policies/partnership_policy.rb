# frozen_string_literal: true

class PartnershipPolicy < TagPolicy
  class Scope < Scope
    def resolve
      Partnership.users_partnerships(user)
    end
  end
end
