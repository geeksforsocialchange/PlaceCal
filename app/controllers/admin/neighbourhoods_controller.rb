# frozen_string_literal: true

module Admin
  class NeighbourhoodsController < Admin::ApplicationController
    before_action :set_neighbourhood, only: %i[show edit update destroy]

    def index
      @neighbourhoods = policy_scope(Neighbourhood).order(:name)
      authorize @neighbourhoods
      respond_to do |format|
        format.html
        format.json { render json: NeighbourhoodDatatable.new(
                                    params,
                                    view_context: view_context,
                                    neighbourhoods: @neighbourhoods
                                  )
                    }
      end
    end

    def new
      @neighbourhood = Neighbourhood.new
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
        redirect_to admin_neighbourhoods_path
      else
        render 'new'
      end
    end

    def update
      authorize @neighbourhood
      if @neighbourhood.update(permitted_attributes(@neighbourhood))
        redirect_to admin_neighbourhoods_path
      else
        render 'edit'
      end
    end

    def destroy
      authorize @neighbourhood
      @neighbourhood.destroy
      respond_to do |format|
        format.html { redirect_to admin_neighbourhoods_url, notice: 'Neighbourhood was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_neighbourhood
      @neighbourhood = Neighbourhood.find(params[:id])
    end
  end
end
