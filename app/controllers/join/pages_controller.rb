# frozen_string_literal: true

# The join.placecal.org marketing site (#3163): mostly-static sales pages plus
# the "book a demo" enquiry form. Routes are constrained to the join subdomain.
class Join::PagesController < ApplicationController
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
    raise ActiveRecord::RecordNotFound unless Components::Join::Base::AUDIENCES.include?(key)

    render Views::Join::Audience.new(audience: key)
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

  # Same form and params as JoinsController#create — the book-a-demo page
  # renders the shared ContactForm.
  def contact_request_params
    params.require(:contact_request).permit(:name, :email, :phone, :job_title, :job_org, :area, :ringback, :more_info, :why)
  end
end
