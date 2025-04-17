# frozen_string_literal: true

# app/components/admin_edit_component.rb
class AdminEdit < ViewComponent::Base
  def initialize(title:, model:)
    super
    @title = "Edit #{@model.to_s.humanize}: #{title}"
    @model = model
  end
end
