# frozen_string_literal: true

class AdminIndexComponent < ViewComponent::Base
  # rubocop:disable Metrics/ParameterLists
  def initialize(title:, model:, data:, new_link:, column_titles: [], columns: %i[], additional_links: [], default: [])
    # rubocop:enable Metrics/ParameterLists
    super
    @title = title
    @model = model
    @data = data
    @new_link = new_link
    @model = model
    @column_titles = column_titles
    @columns = columns
    @additional_links = additional_links
    @default = default
  end

  def model_name
    @model.class.name
  end
end
