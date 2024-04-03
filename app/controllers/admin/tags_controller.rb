# frozen_string_literal: true

module Admin
  class TagsController < Admin::ApplicationController
    before_action :set_tag, only: %i[show edit update destroy]

    def index
      @tags = policy_scope(Tag).order(:name)
      authorize @tags

      respond_to do |format|
        format.html do
          @filter = TagFilter.new(params)
          render :index
        end

        format.json do
          render json: TagDatatable.new(
            params,
            view_context: view_context,
            tags: @tags
          )
        end
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
      @tag = Tag.new(permitted_attributes(Tag.new))
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
            render :new, status: :unprocessable_entity
          end

          format.json { render json: @tag.errors, status: :unprocessable_entity }
        end
      end
    end

    # TODO: Is it a problem that we are missing format.json for the update method here?
    #       We should either have it here, or remove the json format on create, surely
    def update
      authorize @tag
      # permitted_attributes(@tag) causes a crash for some reason
      attributes = params.require(:tag).permit(policy(@tag).permitted_attributes)

      if current_user.partner_admin?
        attributes[:partner_ids] =
          helpers.all_partners_for(@tag, attributes)
      end

      if @tag.update(attributes)
        flash[:success] = 'Tag was saved successfully'
        redirect_to admin_tags_path

      else
        flash.now[:danger] = 'Tag was not saved'
        render 'edit', status: :unprocessable_entity
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
      @tag = Tag.friendly.find(params[:id])
    end
  end
end
