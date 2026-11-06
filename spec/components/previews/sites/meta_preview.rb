# frozen_string_literal: true

class Sites::MetaPreview < Lookbook::Preview
  # @label With permalink
  def with_permalink
    render Components::Sites::Meta.new("https://placecal.org/events/123")
  end

  # @label Without permalink
  def without_permalink
    render Components::Sites::Meta.new(nil)
  end
end
