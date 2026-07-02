# frozen_string_literal: true

class JoinsController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[create update]

  def new
    @join_request = JoinRequest.new
    render Views::Directory::Join.new(join_request: @join_request)
  end

  def create
    @join_request = JoinRequest.new(join_request_params)

    if @join_request.submit
      redirect_to '/', notice: t('directory.join.flash.success')
    else
      flash[:error] = t('directory.join.flash.error')
      render Views::Directory::Join.new(join_request: @join_request)
    end
  end

  private

  def join_request_params
    params.require(:join_request).permit(:name, :email, :phone, :job_title, :job_org, :area, :ringback, :more_info, :why)
  end
end
