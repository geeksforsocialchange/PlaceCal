# frozen_string_literal: true

# app/components/admin_edit_component.rb
class AdminEdit < ViewComponent::Base
  def initialize(title:, model:, id: nil)
    super
    @title = title
    @model = model
    @model_name = model.to_s.humanize
    @id = id
    @page_title = "Edit #{@model_name}: #{title}"
  end
end
