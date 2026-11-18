# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  # Any admin can inspect any event; the page only reads
  def show?
    user.admin_roles.present?
  end
end
