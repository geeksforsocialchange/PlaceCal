# frozen_string_literal: true

class SitePolicy < ApplicationPolicy
  def index?
    user&.role&.root?
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def edit?
    index?
  end

  def update?
    index?
  end
end
