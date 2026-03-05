# frozen_string_literal: true

class CollectionsController < ApplicationController
  include MapMarkers

  before_action :set_collection, only: %i[show edit update destroy]
  before_action :set_site

  def index
    @collections = Collection.all
    render Views::Collections::Index.new(collections: @collections)
  end

  def show
    events = @collection.sorted_events
    @map = get_map_markers(events) if events
    @events = events.distinct.sort_by_time.group_by_day(&:dtstart)

    respond_to do |format|
      format.html do
        render Views::Collections::Show.new(
          collection: @collection, site: @site, events: @events
        )
      end
      format.text { render Views::Events::IndexText.new(events: @events) }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_collection
    @collection = Collection.find(params[:id])
  end
end
