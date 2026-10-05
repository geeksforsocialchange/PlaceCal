# frozen_string_literal: true

class JoinsController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[create update]

  def new
    @join = Join.new(site: current_site)
    render join_view
  end

  def create
    @join = Join.new(join_params)
    @join.site = current_site

    if @join.submit
      redirect_to '/', notice: t('directory.join.flash.success')
    else
      flash[:error] = t('directory.join.flash.error')
      render join_view
    end
  end

  private

  # The form is served on every host: local sites get their own themed view
  # (#3368, D8), the nationwide directory keeps the directory one.
  def join_view
    if current_site
      Views::Sites::Join.new(join: @join, site: current_site)
    else
      Views::Directory::Join.new(join: @join)
    end
  end

  def join_params
    params.require(:join).permit(:name, :email, :phone, :job_title, :job_org, :area, :ringback, :more_info, :why)
  end
end
