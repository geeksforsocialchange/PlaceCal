# frozen_string_literal: true

# app/controllers/admin/collections_controller.rb
module Admin
  class CollectionsController < Admin::ApplicationController
    before_action :set_collection, only: %i[edit update destroy]

    def index
      @collections = Collection.all.reorder(:name)
      authorize current_user
    end

    def show; end

    def new
      @collection = Collection.new
      authorize @collection
    end

    def edit
      authorize @collection
    end

    def create
      @collection = Collection.new(collection_params)
      authorize @collection
      if @collection.save
        redirect_to admin_collections_path
      else
        render 'new'
      end
    end

    def update
      authorize @collection
      if @collection.update_attributes(collection_params)
        redirect_to admin_collections_path
      else
        render 'edit'
      end
    end

    def destroy
      @collection.destroy
      respond_to do |format|
        format.html { redirect_to admin_collections_url, notice: 'Collection was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_collection
      @collection = Collection.find(params[:id])
    end

    def collection_params
      params.require(:collection).permit(
        :id,
        :name,
        :description,
        :image,
        event_ids: []
      )
    end
  end
end
