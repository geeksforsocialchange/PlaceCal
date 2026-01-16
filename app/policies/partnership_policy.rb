# frozen_string_literal: true

class PartnershipPolicy < TagPolicy
  class Scope < Scope
    def resolve
      return Partnership.all if user.root?

      user.partnerships
    end
  end
end
