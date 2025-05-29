# frozen_string_literal: true

# app/components/admin_new.rb
class AdminNew < ViewComponent::Base
  def initialize(model)
    super()
    @model = model
  end

  def model_name
    @model.to_s.humanize
  end
end
