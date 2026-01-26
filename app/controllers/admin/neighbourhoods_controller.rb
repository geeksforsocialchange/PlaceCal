# frozen_string_literal: true

module Admin
  class NeighbourhoodsController < Admin::ApplicationController
    before_action :set_neighbourhood, only: %i[show edit update destroy]

    # GET /admin/neighbourhoods/children?parent_id=123&level=4
    # GET /admin/neighbourhoods/children?level=5 (for countries, no parent)
    # Returns JSON array of neighbourhoods that are descendants of the given parent at the specified level
    # Uses subtree to support smart-skip (finding descendants at any level, not just direct children)
    def children
      authorize Neighbourhood, :index?

      level = params[:level].to_i

      children = if params[:parent_id].present?
                   parent = Neighbourhood.find(params[:parent_id])
                   # Use subtree to find descendants at any level (supports smart-skip)
                   parent.subtree.at_level(level).where.not(id: parent.id)
                 else
                   # Top level (countries) - no parent needed
                   Neighbourhood.roots.at_level(level)
                 end

      children = children
                 .where.not(name: [nil, ''])
                 .latest_release
                 .order(:name)

      render json: children.map { |n|
        {
          id: n.id,
          name: n.name,
          level: n.level,
          unit: n.unit,
          has_children: n.populated_children?
        }
      }
    end

    # GET /admin/neighbourhoods/hierarchy?neighbourhood_id=123
    # Returns the full hierarchy for any neighbourhood level
    def hierarchy
      authorize Neighbourhood, :index?

      neighbourhood = Neighbourhood.find(params[:ward_id] || params[:neighbourhood_id])
      ancestors = neighbourhood.ancestors.order(:ancestry)

      render json: {
        neighbourhood_id: neighbourhood.id,
        neighbourhood_level: neighbourhood.level,
        hierarchy: ancestors.map { |a| { id: a.id, level: a.level, name: a.name } },
        country_id: ancestors.find { |a| a.level == 5 }&.id,
        region_id: ancestors.find { |a| a.level == 4 }&.id,
        county_id: ancestors.find { |a| a.level == 3 }&.id,
        district_id: ancestors.find { |a| a.level == 2 }&.id
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
        render 'new', status: :unprocessable_content
      end
    end

    def update
      authorize @neighbourhood
      if @neighbourhood.update(permitted_attributes(@neighbourhood))
        flash[:success] = 'Neighbourhood was saved'
        redirect_to admin_neighbourhood_path(@neighbourhood)
      else
        flash.now[:danger] = 'Neighbourhood was not saved'
        render 'edit', status: :unprocessable_content
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
