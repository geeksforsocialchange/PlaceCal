# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  # Whoever can edit the source calendar can inspect its events
  def show?
    return true if user.root?
    return false if record.calendar.nil?

    CalendarPolicy.new(user, record.calendar).update?
  end
end
