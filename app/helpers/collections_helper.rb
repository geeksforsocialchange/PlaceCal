# frozen_string_literal: true

module CollectionsHelper
  def options_for_collections
    Collection.all.collect { |p| [p.name, p.id] }
  end
end
