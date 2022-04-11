# frozen_string_literal: true

module Users
  module AuthCommon

    def self.included(klass)
      klass.before_action :devise_check_on_root_site
      klass.after_action :patch_flash
    end

    private

    # action filter:
    #
    # In devise controllers: push all users on any subdomain of placecal to 
    #   authenticate on the base placecal.org site so the site is set up
    #   properly and the styling will work
    #
    def devise_check_on_root_site
      return if current_user.present?
      return if not request.subdomain.present?

      redirect_to url_for(subdomain: nil)
    end

    def patch_flash
      # notice -> success
      # alert -> danger
      if flash.key?(:notice)
        flash[:success] = flash[:notice]
        flash.delete :notice
      end

      if flash.key?(:alert)
        flash[:danger] = flash[:alert]
        flash.delete :alert
      end

      if flash.now.flash.key?(:notice)
        flash.now[:success] = flash.now[:notice]
        flash.now.flash.delete :notice
      end

      if flash.now.flash.key?(:alert)
        flash.now[:danger] = flash.now[:alert]
        flash.now.flash.delete :alert
      end
    end
  end

end
