# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  # Any admin can inspect any event; the page only reads
  def show?
    user.any_admin_role?
  end
end
