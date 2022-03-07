# frozen_string_literal: true

module Admin
  class SitesController < Admin::ApplicationController
    before_action :set_site, only: %i[update destroy]
    before_action :set_variables_for_sites_neighbourhoods_selection, only: [:new, :edit]

    def index
      @sites = policy_scope(Site).order({ :updated_at => :desc }, :name)
      authorize @sites

      respond_to do |format|
        format.html
        format.json {
          render json: SiteDatatable.new(
            params,
            view_context: view_context,
            sites: @sites
          )
        }
      end
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
        flash[:success] = 'Site has been created'
        redirect_to admin_sites_path

      else
        flash.now[:danger] = 'Site was not created'
        set_variables_for_sites_neighbourhoods_selection
        render 'new'
      end
    end

    def update
      authorize @site
      if @site.update(permitted_attributes(@site))
        flash[:success] = 'Site was saved successfully'
        redirect_to admin_sites_path

      else
        flash.now[:danger] = 'Site was not saved'
        set_variables_for_sites_neighbourhoods_selection
        render 'edit'
      end
    end

    def destroy
      authorize @site
      @site.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Site was deleted'
          redirect_to admin_sites_url
        end

        format.json { head :no_content }
      end
    end

    private

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
