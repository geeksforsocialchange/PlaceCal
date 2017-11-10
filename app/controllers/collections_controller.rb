class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[show edit update destroy]

  # GET /collections
  # GET /collections.json
  def index
    @collections = Collection.all
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @events = @collection.sorted_events
    @map = @events.map(&:place).uniq.map do |p|
      next unless p&.address&.latitude
      {
        lat: p.address.latitude,
        lon: p.address.longitude,
        name: p.name,
        id: p.id
      }
    end
    @events = sort_events(@events, 'time')
  end

  # GET /collections/new
  # def new
  #   @collection = Collection.new
  # end

  # # GET /collections/1/edit
  # def edit
  # end

  # # POST /collections
  # # POST /collections.json
  # def create
  #   @collection = Collection.new(collection_params)

  #   respond_to do |format|
  #     if @collection.save
  #       format.html { redirect_to @collection, notice: 'Collection was successfully created.' }
  #       format.json { render :show, status: :created, location: @collection }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @collection.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # PATCH/PUT /collections/1
  # # PATCH/PUT /collections/1.json
  # def update
  #   respond_to do |format|
  #     if @collection.update(collection_params)
  #       format.html { redirect_to @collection, notice: 'Collection was successfully updated.' }
  #       format.json { render :show, status: :ok, location: @collection }
  #     else
  #       format.html { render :edit }
  #       format.json { render json: @collection.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # DELETE /collections/1
  # # DELETE /collections/1.json
  # def destroy
  #   @collection.destroy
  #   respond_to do |format|
  #     format.html { redirect_to collections_url, notice: 'Collection was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_collection
    @collection = Collection.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def collection_params
    params.require(:collection).permit(:name, :description)
  end
end
