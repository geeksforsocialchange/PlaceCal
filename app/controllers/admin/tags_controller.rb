# frozen_string_literal: true

module Admin
  class TagsController < Admin::ApplicationController
    before_action :set_tag, only: %i[show edit update destroy]

    def index
      @tags = policy_scope(Tag).order(:name)
      authorize @tags

      respond_to do |format|
        format.html
        format.json {
          render json: TagDatatable.new(
            params,
            view_context: view_context,
            tags: @tags
          )
        }
      end
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
          format.html do
            flash[:success] = 'Tag has been created'
            redirect_to admin_tags_path
          end

          format.json { render :show, status: :created, location: @tag }
        else
          format.html do
            flash.now[:danger] = 'Tag was not created'
            render :new 
          end

          format.json { render json: @tag.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      authorize @tag
      if @tag.update(tag_params)
        flash[:success] = 'Tag was saved successfully'
        redirect_to admin_tags_path

      else
        flash.now[:danger] = 'Tag was not saved'
        render 'edit'
      end
    end

    def destroy
      authorize @tag
      @tag.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Tag was deleted'
          redirect_to admin_tags_url
        end

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
