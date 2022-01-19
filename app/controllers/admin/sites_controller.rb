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
      inject_sites_neighbourhoods_attributes(neighbourhood_ids_param) if neighbourhood_ids_param
      if @site.update(permitted_attributes(@site))
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

    def neighbourhood_ids_param
      @_params[:site][:neighbourhood_ids]
    end

    def inject_sites_neighbourhoods_attributes(neighbourhood_ids)
      result_attributes = {}

      # Grab the ids requested, filter out null entries and convert to integer
      neighbourhood_ids = neighbourhood_ids.filter { |id| id != '' }.map(&:to_i)

      # Grab the existing neighbourhoods, and their ids
      existing_sites_neighbourhoods = SitesNeighbourhood.where(relation_type: 'Secondary', site_id: @site.id)
      existing_sites_neighbourhoods_ids = existing_sites_neighbourhoods.collect(&:neighbourhood_id)

      # Delete items that are not in the neighbourhood ids pile
      existing_sites_neighbourhoods.each do |sn|
        attrib = { '_destroy': true,
                   'id': sn.id.to_s,
                   'relation_type': 'Secondary'
                 }
        result_attributes[sn.neighbourhood_id.to_s] = attrib unless neighbourhood_ids.include? sn.neighbourhood_id
      end

      # Add the primary id to avoid creating a duplicate secondary neighbourhood association
      existing_sites_neighbourhoods_ids << @site.primary_neighbourhood.id

      # Create items that do not already exist
      neighbourhood_ids.each do |id|
        sn = { 'relation_type': 'Secondary' }
        result_attributes[id.to_s] = sn unless existing_sites_neighbourhoods_ids.include? id
      end

      @site.sites_neighbourhoods_attributes = result_attributes
    end

    def set_site
      @site = Site.friendly.find(params[:id])
    end

    def set_variables_for_sites_neighbourhoods_selection
      @all_neighbourhoods = policy_scope(Neighbourhood).order(:name).where(unit: 'ward')
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
