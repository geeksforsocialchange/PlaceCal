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
      # this returns an array which is breaking @tag.update. not sure why the original didn't?
      # needs to be ActionController::Parameters
      # attributes = policy(@tag).permitted_attributes

      # this method call breaks with @tag
      #
      # LOG
      # 17:18:27 web.1        | Started PATCH "/tags/c2" for 127.0.0.1 at 2023-09-23 17:18:27 +0100
      # 17:18:27 web.1        |    (0.8ms)  SELECT "schema_migrations"."version" FROM "schema_migrations" ORDER BY "schema_migrations"."version" ASC
      # 17:18:27 web.1        | Processing by Admin::TagsController#update as TURBO_STREAM
      # 17:18:27 web.1        |   Parameters: {"authenticity_token"=>"8KmLIyTpkRPZmhCNzFjLDCt0xgyEyJibGMLnSr0_IszZe80Lg3jdG65tz4LEQQJqSnFbQIH2zDIqfINShAHvhw", "tag"=>{"name"=>"C23223 Connecting Communities", "slug"=>"c2", "description"=>"", "partner_ids"=>[""]}, "commit"=>"Save", "subdomain"=>"admin", "id"=>"c2"}
      # 17:18:27 web.1        |    (0.5ms)  SELECT COUNT(*) FROM "sites"
      # 17:18:27 web.1        |   ↳ app/controllers/application_controller.rb:92:in `current_site'
      # 17:18:27 web.1        |   User Load (0.4ms)  SELECT "users".* FROM "users" WHERE "users"."id" = $1 ORDER BY "users"."id" ASC LIMIT $2  [["id", 162], ["LIMIT", 1]]
      # 17:18:27 web.1        |   Tag Load (0.3ms)  SELECT "tags".* FROM "tags" WHERE "tags"."slug" = $1 LIMIT $2  [["slug", "c2"], ["LIMIT", 1]]
      # 17:18:27 web.1        |   ↳ app/controllers/admin/tags_controller.rb:111:in `set_tag'
      # 17:18:27 web.1        |   Partner Exists? (1.0ms)  SELECT 1 AS one FROM "partners" INNER JOIN "partners_users" ON "partners"."id" = "partners_users"."partner_id" WHERE "partners_users"."user_id" = $1 LIMIT $2  [["user_id", 162], ["LIMIT", 1]]
      # 17:18:27 web.1        |   ↳ app/models/user.rb:89:in `partner_admin?'
      # 17:18:27 web.1        |   Tag Exists? (1.1ms)  SELECT 1 AS one FROM "tags" INNER JOIN "tags_users" ON "tags"."id" = "tags_users"."tag_id" WHERE "tags_users"."user_id" = $1 LIMIT $2  [["user_id", 162], ["LIMIT", 1]]
      # 17:18:27 web.1        |   ↳ app/models/user.rb:93:in `tag_admin?'
      # 17:18:27 web.1        | Completed 400 Bad Request in 69ms (ActiveRecord: 15.3ms | Allocations: 74331)
      # 17:18:27 web.1        |
      # 17:18:27 web.1        |
      # 17:18:27 web.1        |
      # 17:18:27 web.1        | ActionController::ParameterMissing - param is missing or the value is empty: partnership
      # 17:18:27 web.1        | Did you mean?  action
      # 17:18:27 web.1        |                controller
      # 17:18:27 web.1        |                authenticity_token
      # 17:18:27 web.1        |                _method:
      # 17:18:27 web.1        |   app/controllers/admin/tags_controller.rb:68:in `update'
      # 17:18:27 web.1        |
      # 17:18:27 web.1        | Started GET "/tags/c2/edit" for 127.0.0.1 at 2023-09-23 17:18:27 +0100
      # 17:18:27 web.1        | Processing by Admin::TagsController#edit as HTML
      # 17:18:27 web.1        |   Parameters: {"subdomain"=>"admin", "id"=>"c2"}
      # 17:18:27 web.1        |    (0.6ms)  SELECT COUNT(*) FROM "sites"
      # 17:18:27 web.1        |   ↳ app/controllers/application_controller.rb:92:in `current_site'
      # 17:18:27 web.1        |   User Load (0.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = $1 ORDER BY "users"."id" ASC LIMIT $2  [["id", 162], ["LIMIT", 1]]
      #
      # bad method call
      # attributes = permitted_attributes(@tag)

      # original method call
      Rails.logger.debug '~' * 34
      Rails.logger.debug params
      Rails.logger.debug '~' * 34
      attributes = permitted_attributes(Tag.new)
      Rails.logger.debug '~' * 34
      Rails.logger.debug 'what sort of class????'
      Rails.logger.debug attributes.class

      if current_user.partner_admin?
        attributes[:partner_ids] =
          helpers.all_partners_for(@tag, attributes)
      end

      if current_user.tags.include?(@tag)
        Rails.logger.debug 'THIS IS THE TAG ADMIN'
        attributes[:name] = params[:tag][:name]
        attributes[:slug] = params[:tag][:slug]
        attributes[:description] = params[:tag][:description]
      end

      Rails.logger.debug '#' * 60
      Rails.logger.debug 'these are the attributes'
      Rails.logger.debug attributes
      Rails.logger.debug '#' * 60

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
