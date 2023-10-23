# frozen_string_literal: true

class CollectionsController < ApplicationController
  include MapMarkers

  before_action :set_collection, only: %i[show edit update destroy]
  before_action :set_site

  def index
    @collections = Collection.all
  end

  def show
    @events = @collection.sorted_events
    @map = get_map_markers(@events) if @events
    @events = sort_events(@events, 'time')

    respond_to do |format|
      format.html
      format.text
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_collection
    @collection = Collection.find(params[:id])
  end
end
