# frozen_string_literal: true

class PartnershipsController < ApplicationController
  before_action :set_site
  before_action :require_directory_site

  # GET /partnerships
  def index
    @partnerships = Partnership
                    .joins(:partners)
                    .where(partners: { hidden: false })
                    .distinct
                    .order(:name)

    @title = 'Partnerships'

    render Views::Partnerships::Index.new(
      partnerships: @partnerships,
      site: @site
    )
  end

  # GET /partnerships/:id
  def show
    @partnership = Partnership.friendly.find(params[:id])
    @partners = @partnership.partners.visible.order(:name)
    @title = @partnership.name

    render Views::Partnerships::Show.new(
      partnership: @partnership,
      partners: @partners,
      site: @site
    )
  end

  private

  def require_directory_site
    redirect_to root_path unless current_site&.directory_site?
  end
end
