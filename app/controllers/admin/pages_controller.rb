module Admin
  class PagesController < Admin::ApplicationController

    def home
      if current_user&.role&.root?
        @turfs = Turf.all.order(:name)
        @partners = Partner.all.order(:name)
        @places = Place.all.order(:name)
      else
        @turfs = current_user.turfs
        @partners = Partner.joins(:turfs).where(turfs: { id: @turfs }).distinct
        @places = Place.joins(:turfs).where(turfs: { id: @turfs }).distinct
      end
    end
  end
end
