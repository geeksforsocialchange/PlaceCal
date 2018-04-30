module Admin
  class TurfsController < Admin::ApplicationController

    def index
      @turfs = policy_scope(Turf)
    end

    def new
      @turf = Turf.new
    end

    def edit
      authorize current_user, :check_root_role?
      @turf = Turf.find(params[:id])
      @partners = @turf.partners
      @places = @turf.places
    end

    def create 
      @turf = Turf.new(turf_params)
      if @turf.save
        redirect_to admin_turfs_path
      else
        render 'new'
      end
    end

    def update
      @turf = Turf.find(params[:id])
      authorize current_user, :check_root_role?
      if @turf.update_attributes(turf_params)
        redirect_to admin_turfs_path
      else
        render 'edit'
      end
    end

    private

    def turf_params
      params.require(:turf).permit(:name, :slug, :description, :turf_type) 
    end

  end
end

