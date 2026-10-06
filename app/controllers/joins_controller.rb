# frozen_string_literal: true

class JoinsController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[create update]

  def new
    @contact_request = ContactRequest.new(site: current_site)
    render join_view
  end

  def create
    @contact_request = ContactRequest.new(contact_request_params)
    @contact_request.site = current_site

    if @contact_request.submit
      redirect_to '/', notice: t('directory.join.flash.success')
    else
      # 422 so Turbo renders the re-displayed form; flash.now so the error
      # doesn't leak onto the next page.
      flash.now[:error] = t('directory.join.flash.error')
      render join_view, status: :unprocessable_content
    end
  end

  private

  # The form is served on every host: local sites get their own themed view
  # (#3368, D8), the nationwide directory keeps the directory one.
  def join_view
    if current_site
      Views::Sites::Join.new(contact_request: @contact_request, site: current_site)
    else
      Views::Directory::Join.new(contact_request: @contact_request)
    end
  end

  def contact_request_params
    params.require(:contact_request).permit(*ContactRequest::PERMITTED_PARAMS)
  end
end
