# frozen_string_literal: true

module Superadmin
  class UsersController < Superadmin::ApplicationController
    def update
      if requested_resource.update_without_password(resource_params)
        redirect_to([namespace, requested_resource],
                    notice: translate_with_resource('update.success'))
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }
      end
    end
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = User.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   User.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
