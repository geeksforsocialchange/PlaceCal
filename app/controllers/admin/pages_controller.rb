module Admin
  class PagesController < Admin::ApplicationController
    # before_action :secretary_authenticate

    def home
      @turfs = current_user.turfs
      @partners = Partner.joins(:turfs).where(turfs: { id: @turfs }).distinct
      @places = Place.joins(:turfs).where(turfs: { id: @turfs }).distinct
    end
  end
end
