# frozen_string_literal: true

module Admin
  class TurfsController < Admin::ApplicationController
    before_action :set_turf, only: %i[show edit update destroy]

    def index
      @turfs = policy_scope(Turf).order(:name)
      authorize @turfs
    end

    def new
      @turf = Turf.new
      authorize @turf
    end

    def edit
      authorize @turf
      @partners = @turf.partners
      @places = @turf.places
    end

    def create
      @turf = Turf.new(turf_params)
      authorize @turf
      respond_to do |format|
        if @turf.save
          format.html { redirect_to admin_turfs_path, notice: 'Turf was successfully created.' }
          format.json { render :show, status: :created, location: @turf }
        else
          format.html { render :new }
          format.json { render json: @turf.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      authorize @turf
      if @turf.update_attributes(turf_params)
        redirect_to admin_turfs_path
      else
        render 'edit'
      end
    end

    def destroy
      @turf.destroy
      respond_to do |format|
        format.html { redirect_to admin_turfs_url, notice: 'Turf was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_turf
      @turf = Turf.find(params[:id])
    end

    def turf_params
      params.require(:turf).permit(:name, :slug, :description)
    end
  end
end
