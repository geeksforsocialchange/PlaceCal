# frozen_string_literal: true

module Admin
  class SitesController < Admin::ApplicationController
    # TODO: Undo this shotgun approach to setting memeber variables
    before_action :set_site_and_neighbourhoods

    def index
      @sites = Site.all
      authorize current_user
    end

    def show; end

    def new
      @site = Site.new
      @site.build_sites_turf
      authorize @site
    end

    def edit
      authorize @site
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
      authorize @site
      if @site.update_attributes(site_params)
        redirect_to admin_sites_path
      else
        render 'edit'
      end
    end

    def destroy
      @site.destroy
      respond_to do |format|
        format.html { redirect_to admin_sites_url, notice: 'Site was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_site_and_neighbourhoods
      @neighbourhoods = Neighbourhood.all
      @site = Site.friendly.find(params[:id])
      if @site
        @primary_neighbourhood_id = @site.primary_neighbourhood&.id
        @secondary_neighbourhood_ids = @site.secondary_neighbourhoods.pluck(:id)
      end
    end

    def site_params
      params.require(:site).permit(
        :id,
        :name,
        :slug,
        :description,
        :domain,
        :logo,
        :footer_logo,
        :hero_image,
        :hero_image_credit,
        :site_admin_id,
        sites_neighbourhoods_attributes: %i[_destroy id turf_id relation_type],
        sites_neighbourhood_attributes: %i[_destroy id turf_id relation_type]
      )
    end
  end
end
