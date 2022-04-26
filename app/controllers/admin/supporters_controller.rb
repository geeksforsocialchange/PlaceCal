# frozen_string_literal: true

# app/controllers/admin/supporters_controller.rb
module Admin
  class SupportersController < Admin::ApplicationController
    before_action :set_supporter, only: %i[edit update destroy]

    def index
      @supporters = Supporter.all.reorder(:name)
      authorize current_user
    end

    def show; end

    def new
      @supporter = Supporter.new
      authorize @supporter
    end

    def edit
      authorize @supporter
    end

    def create
      @supporter = Supporter.new(supporter_params)
      authorize @supporter
      if @supporter.save
        flash[:success] = 'Supporter has been created'
        redirect_to admin_supporters_path

      else
        flash.now[:danger] = 'Supporter not created'
        render 'new', status: :unprocessable_entity
      end
    end

    def update
      authorize @supporter
      if @supporter.update(supporter_params)
        flash[:success] = 'Supporter has been updated'
        redirect_to admin_supporters_path

      else
        flash.now[:danger] = 'Supporter was not updated'
        render 'edit', status: :unprocessable_entity
      end
    end

    def destroy
      authorize @supporter
      @supporter.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Supporter has been deleted'
          redirect_to admin_supporters_url
        end

        format.json { head :no_content }
      end
    end

    private

    def set_supporter
      @supporter = Supporter.find(params[:id])
    end

    def supporter_params
      params.require(:supporter).permit(
        :id,
        :name,
        :url,
        :description,
        :logo,
        :is_global,
        :weight,
        site_ids: []
      )
    end
  end
end
