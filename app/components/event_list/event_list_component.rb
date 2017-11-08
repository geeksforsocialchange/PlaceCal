# frozen_string_literal: true

# app/components/event_list/event_list_component.rb
class EventListComponent < MountainView::Presenter
  properties :events, :pointer, :period, :sort, :path
  property :show_breadcrumb, default: true
end
