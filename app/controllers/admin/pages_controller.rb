# frozen_string_literal: true

module Admin
  class PagesController < Admin::ApplicationController
    def home
      if current_user&.role&.root?
        @turfs = Turf.all.order(:name)
        @partners = Partner.all.order(:name)
      else
        @turfs = current_user.turfs
        @partners = Partner.joins(:turfs).where(turfs: { id: @turfs }).distinct
      end
    end
  end
end
