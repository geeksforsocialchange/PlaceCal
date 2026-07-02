# frozen_string_literal: true

# The join.placecal.org marketing site (#3163): mostly-static sales pages plus
# the "book a demo" enquiry form. Routes are constrained to the join subdomain
# and the config.x.join_site_enabled flag (config/initializers/join_site.rb),
# so nothing here is reachable until the site is switched on.
class JoinPagesController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[demo_create]

  STATS_CACHE_TTL = 1.day

  def home
    # Shares the 'directory/stats' cache with the nationwide directory
    # homepage so the two sites quote the same numbers.
    stats = Rails.cache.fetch('directory/stats', expires_in: STATS_CACHE_TTL) do
      DirectoryStatsQuery.new.call
    end
    render Views::Join::Home.new(stats: stats)
  end

  def audiences
    render Views::Join::Audiences.new
  end

  def audience
    key = params[:slug].to_s.tr('-', '_')
    raise ActiveRecord::RecordNotFound unless DemoRequest::AUDIENCES.include?(key)

    render Views::Join::Audience.new(audience: key)
  end

  def features
    render Views::Join::Features.new
  end

  def our_story
    render Views::Join::OurStory.new
  end

  def pricing
    render Views::Join::Pricing.new
  end

  def demo
    render Views::Join::Demo.new(demo_request: DemoRequest.new)
  end

  def demo_create
    @demo_request = DemoRequest.new(demo_params)

    if @demo_request.submit
      redirect_to join_root_path, notice: t('join.demo.flash.success')
    else
      flash.now[:error] = t('join.demo.flash.error')
      render Views::Join::Demo.new(demo_request: @demo_request), status: :unprocessable_content
    end
  end

  private

  def demo_params
    params.require(:demo_request).permit(:name, :email, :organisation, :audience, :message)
  end
end
