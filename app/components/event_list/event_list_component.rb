# frozen_string_literal: true

# app/components/event_list/event_list_component.rb
class EventListComponent < MountainView::Presenter
  properties :events, :neighbourhood_id, :pointer, :period, :sort, :path, :repeating
  property :show_breadcrumb, default: true
  property :show_paginator, default: true
end
