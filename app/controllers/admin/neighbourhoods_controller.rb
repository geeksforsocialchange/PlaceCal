# frozen_string_literal: true

module Admin
  class NeighbourhoodsController < Admin::ApplicationController
    before_action :set_neighbourhood, only: %i[show edit update destroy]

    # GET /admin/neighbourhoods/children?parent_id=123&unit=district
    # Returns JSON array of neighbourhoods that are children of the given parent
    def children
      authorize Neighbourhood, :index?

      parent = Neighbourhood.find(params[:parent_id])
      unit = params[:unit]

      # For "district" level, include both counties and districts
      units = unit == 'district' ? %w[county district] : [unit]

      # Get children at the specified unit level(s)
      children = parent.descendants
                       .where(unit: units)
                       .where.not(name: [nil, ''])
                       .latest_release
                       .order(:name)

      render json: children.map { |n| { id: n.id, name: n.name, unit: n.unit } }
    end

    # GET /admin/neighbourhoods/hierarchy?neighbourhood_id=123
    # Returns the full hierarchy for any neighbourhood level
    def hierarchy
      authorize Neighbourhood, :index?

      neighbourhood = Neighbourhood.find(params[:ward_id] || params[:neighbourhood_id])

      # Find the region (direct ancestor or self if it's a region)
      region = neighbourhood.unit == 'region' ? neighbourhood : neighbourhood.region

      # Determine which dropdown each level maps to based on neighbourhood unit
      district_level =
        case neighbourhood.unit
        when 'ward'
          neighbourhood.ancestors.where(unit: %w[county district]).order(:id).last
        when 'county', 'district'
          neighbourhood
        end

      render json: {
        region_id: region&.id,
        district_id: district_level&.id,
        neighbourhood_id: neighbourhood.id,
        neighbourhood_unit: neighbourhood.unit
      }
    end

    def index
      @neighbourhoods = policy_scope(Neighbourhood)
      authorize @neighbourhoods

      respond_to do |format|
        format.html { @neighbourhoods = @neighbourhoods.order(:name) }
        format.json do
          render json: NeighbourhoodDatatable.new(
            params,
            view_context: view_context,
            neighbourhoods: @neighbourhoods,
            current_user: @current_user
          )
        end
      end
    end

    def new
      @neighbourhood = Neighbourhood.new
      authorize @neighbourhood
    end

    def show
      authorize @neighbourhood
    end

    def edit
      authorize @neighbourhood
      @users = @neighbourhood.users
    end

    def create
      @neighbourhood = Neighbourhood.new(permitted_attributes(Neighbourhood))
      authorize @neighbourhood
      if @neighbourhood.save
        flash[:success] = 'Neighbourhood saved'
        redirect_to admin_neighbourhoods_path
      else
        flash.now[:danger] = 'Neighbourhood was not saved'
        render 'new', status: :unprocessable_entity
      end
    end

    def update
      authorize @neighbourhood
      if @neighbourhood.update(permitted_attributes(@neighbourhood))
        flash[:success] = 'Neighbourhood was saved'
        redirect_to admin_neighbourhoods_path

      else
        flash.now[:danger] = 'Neighbourhood was not saved'
        render 'edit', status: :unprocessable_entity
      end
    end

    def destroy
      authorize @neighbourhood
      @neighbourhood.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Neighbourhood was deleted'
          redirect_to admin_neighbourhoods_url
        end
        format.json { head :no_content }
      end
    end

    private

    def set_neighbourhood
      @neighbourhood = Neighbourhood.find(params[:id])
    end
  end
end
