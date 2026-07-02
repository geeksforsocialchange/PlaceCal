# frozen_string_literal: true

class JoinsController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[create update]

  def new
    @contact_request = ContactRequest.new
    render Views::Directory::Join.new(contact_request: @contact_request)
  end

  def create
    @contact_request = ContactRequest.new(contact_request_params)

    if @contact_request.submit
      redirect_to '/', notice: t('directory.join.flash.success')
    else
      flash[:error] = t('directory.join.flash.error')
      render Views::Directory::Join.new(contact_request: @contact_request)
    end
  end

  private

  def contact_request_params
    params.require(:contact_request).permit(:name, :email, :phone, :job_title, :job_org, :area, :ringback, :more_info, :why)
  end
end
