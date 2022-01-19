# frozen_string_literal: true

module Admin
  class SitesController < Admin::ApplicationController
    before_action :set_site, only: %i[update destroy]
    before_action :set_variables_for_sites_neighbourhoods_selection, only: [:new, :edit]

    def index
      @sites = policy_scope(Site).order(:name)
      authorize @sites
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
      @site = Site.new(permitted_attributes(Site))
      authorize @site
      if @site.save
        redirect_to admin_sites_path
      else
        render 'new'
      end
    end

    def update
      authorize @site
      if update_site(@site)
        redirect_to admin_sites_path
      else
        set_variables_for_sites_neighbourhoods_selection
        render 'edit'
      end
    end

    def destroy
      authorize @site
      @site.destroy
      respond_to do |format|
        format.html { redirect_to admin_sites_url, notice: 'Site was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def update_site(attributes)
      updated = @site.update(permitted_attributes(attributes))
      update_sites_neighbourhoods(@_params[:site][:neighbourhood_ids]) if updated
      updated
    end

    def update_sites_neighbourhoods(neighbourhood_ids)
      existing_sites_neighbourhoods = SitesNeighbourhood.where(relation_type: 'Secondary', site_id: @site.id)
      existing_sites_neighbourhoods_ids = existing_sites_neighbourhoods.collect(&:neighbourhood_id)

      existing_sites_neighbourhoods.each do |sn|
        sn.destroy unless neighbourhood_ids.include? sn.neighbourhood_id
      end
      neighbourhood_ids.each do |id|
        sn = { relation_type: 'Secondary', neighbourhood_id: id, site_id: @site.id }
        SitesNeighbourhood.create(sn) unless existing_sites_neighbourhoods_ids.include? id
      end
    end

    def set_site
      @site = Site.friendly.find(params[:id])
    end

    def set_variables_for_sites_neighbourhoods_selection
      @all_neighbourhoods = policy_scope(Neighbourhood).order(:name)
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
  end
end
