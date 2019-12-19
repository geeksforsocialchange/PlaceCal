# frozen_string_literal: true

module Admin
  class TagsController < Admin::ApplicationController
    before_action :set_tag, only: %i[show edit update destroy]

    def index
      @tags = policy_scope(Tag).order(:name)
      authorize @tags
    end

    def new
      @tag = Tag.new
      authorize @tag
    end

    def edit
      authorize @tag
      @partners = @tag.partners
    end

    def create
      @tag = Tag.new(tag_params)
      authorize @tag
      respond_to do |format|
        if @tag.save
          format.html { redirect_to admin_tags_path, notice: 'Tag was successfully created.' }
          format.json { render :show, status: :created, location: @tag }
        else
          format.html { render :new }
          format.json { render json: @tag.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      authorize @tag
      if @tag.update(tag_params)
        redirect_to admin_tags_path
      else
        render 'edit'
      end
    end

    def destroy
      @tag.destroy
      respond_to do |format|
        format.html { redirect_to admin_tags_url, notice: 'Tag was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name, :slug, :description)
    end
  end
end
