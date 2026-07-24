# frozen_string_literal: true

class JoinsController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[create]

  def new
    @contact_request = ContactRequest.new
    render Views::Directory::Join.new(contact_request: @contact_request)
  end

  def create
    @contact_request = ContactRequest.new(contact_request_params)

    if @contact_request.submit
      redirect_to '/', notice: t('directory.join.flash.success')
    else
      # 422 so Turbo renders the re-displayed form; flash.now so the error
      # doesn't leak onto the next page.
      flash.now[:error] = t('directory.join.flash.error')
      render Views::Directory::Join.new(contact_request: @contact_request), status: :unprocessable_content
    end
  end

  private

  def contact_request_params
    params.require(:contact_request).permit(*ContactRequest::PERMITTED_PARAMS)
  end
end
