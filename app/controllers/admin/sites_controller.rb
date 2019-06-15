# frozen_string_literal: true

module Admin
  class SitesController < Admin::ApplicationController
    before_action :set_site, only: %i[update destroy]
    before_action :set_variables_for_sites_neighbourhoods_selection, only: [:new, :edit]

    def index
      @sites = Site.all.order(:name)
      authorize current_user
    end

    def show; end

    def new
      @site = Site.new
      @site.build_sites_neighbourhood
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
        set_variables_for_sites_neighbourhoods_selection
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

    def set_site
      @site = Site.friendly.find(params[:id])
    end

    def set_variables_for_sites_neighbourhoods_selection
      @all_neighbourhoods = Neighbourhood.all.order(:name)
      begin
        set_site
      rescue ActiveRecord::RecordNotFound
        @primary_neighbourhood_id = nil
        @secondary_neighbourhood_ids = []
        @sites_neighbourhoods_ids = {}
      else
        @primary_neighbourhood_id = @site.primary_neighbourhood&.id
        @secondary_neighbourhood_ids = @site.secondary_neighbourhoods.pluck(:id)

        # Make a dictionary of { neighbourhood_id => sites_neighbourhood_id }
        @sites_neighbourhoods_ids =
          @site.sites_neighbourhoods.map {|sn| {sn.neighbourhood_id => sn.id}}
          .reduce({}, :merge)
      end
    end

    def site_params
      params.require(:site).permit(
        :id,
        :name,
        :place_name,
        :tagline,
        :slug,
        :description,
        :domain,
        :logo,
        :footer_logo,
        :hero_image,
        :hero_image_credit,
        :site_admin_id,
        sites_neighbourhoods_attributes: %i[_destroy id neighbourhood_id relation_type],
        sites_neighbourhood_attributes: %i[_destroy id neighbourhood_id relation_type]
      )
    end
  end
end
