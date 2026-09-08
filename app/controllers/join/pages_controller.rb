# frozen_string_literal: true

# The join.placecal.org marketing site (#3163): mostly-static sales pages plus
# the "book a demo" enquiry form. Routes are constrained to the join subdomain.
class Join::PagesController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[demo_create]

  def home
    render Views::Join::Home.new(stats: DirectoryStatsQuery.fetch_cached)
  end

  def audiences
    render Views::Join::Audiences.new
  end

  # Match the dashed slug exactly — accepting the underscored key form too
  # would serve every audience page at two URLs, each claiming to be canonical.
  def audience
    raise ActiveRecord::RecordNotFound unless Components::Join::Base::AUDIENCE_SLUGS.include?(params[:slug])

    render Views::Join::Audience.new(audience: params[:slug].tr('-', '_'))
  end

  def features
    render Views::Join::Features.new
  end

  # The directory's Our Story page, reused in the join chrome with the
  # closing CTA pointed at book-a-demo.
  def our_story
    render Views::Directory::OurStory.new(cta_path: join_demo_path)
  end

  def pricing
    render Views::Join::Pricing.new
  end

  def demo
    render Views::Join::Demo.new(contact_request: ContactRequest.new)
  end

  def demo_create
    @contact_request = ContactRequest.new(contact_request_params)

    if @contact_request.submit
      redirect_to join_root_path, notice: t('join.demo.flash.success')
    else
      flash.now[:error] = t('join.demo.flash.error')
      render Views::Join::Demo.new(contact_request: @contact_request), status: :unprocessable_content
    end
  end

  private

  def contact_request_params
    params.require(:contact_request).permit(*ContactRequest::PERMITTED_PARAMS)
  end
end
