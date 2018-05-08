module Admin
  class SitesController < Admin::ApplicationController

    def index
      @sites = policy_scope(Site)
    end

    def show
    end

    def new
      @site = Site.new
      @turfs = Turf.all
      @site.build_sites_turf
      authorize @site
    end

    def edit
      @site = Site.friendly.find(params[:id])
      authorize @site
      @turfs = Turf.all
      @sites_turfs = @site.secondary_turfs.pluck(:id)
    end

    def create
      @site = Site.new(site_params)
      authorize @site
      if @site.save
        redirect_to admin_sites_path
      else
        render 'new'
      end
    end

    def update
      @site = Site.friendly.find(params[:id])
      authorize @site
      if @site.update_attributes(site_params)
        redirect_to admin_sites_path
      else
        render 'edit'
      end
    end

    private

    def site_params
      params.require(:site).permit(
        :name,
        :slug,
        :description,
        :domain,
        sites_turfs_attributes: %i[turf_id relation_type],
        sites_turf_attributes: %i[turf_id relation_type]
      )
    end
  end
end
