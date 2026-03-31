# frozen_string_literal: true

class MetaPreview < Lookbook::Preview
  # @label With permalink
  def with_permalink
    render Components::Meta.new("/events/123")
  end

  # @label Without permalink
  def without_permalink
    render Components::Meta.new(nil)
  end
end
