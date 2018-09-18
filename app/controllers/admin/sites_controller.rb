# frozen_string_literal: true

module Admin
  class SitesController < Admin::ApplicationController
    before_action :set_site, only: %i[edit update destroy]
    before_action :set_turfs, except: %i[index :show, :destroy]

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

    def set_turfs
      @turfs = Turf.all
    end

    def set_site
      @site = Site.friendly.find(params[:id])
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
        sites_turfs_attributes: %i[_destroy id turf_id relation_type],
        sites_turf_attributes: %i[_destroy id turf_id relation_type]
      )
    end
  end
end
