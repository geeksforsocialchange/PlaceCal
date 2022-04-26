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
        flash[:success] = 'Collection has been saved'
        redirect_to admin_collections_path
      else
        flash.now[:danger] = 'Collection did not save'
        render 'new', status: :unprocessable_entity
      end
    end

    def update
      authorize @collection
      if @collection.update(collection_params)
        flash.now[:success] = 'Collection has been saved'
        render 'edit'
      else
        flash.now[:danger] = 'Collection did not save'
        render 'edit', status: :unprocessable_entity
      end
    end

    def destroy
      authorize @collection
      @collection.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Collection was deleted successfully'
          redirect_to admin_collections_url
        end

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
        :route,
        :description,
        :image,
        event_ids: []
      )
    end
  end
end
