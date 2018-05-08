module Superadmin
  class PartnersController < Superadmin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = Partner.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:

    # def index
    #   @partners = Partner.order(:name)
    #   @map = generate_points(@partners) if @partners.detect(&:address)
    # end

    def find_resource(param)
      Partner.find_by!(slug: param)
    end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
