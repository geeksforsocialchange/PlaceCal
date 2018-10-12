module Admin
  class OmniauthCallbacksController < Admin::ApplicationController

    def setup
      request.env['omniauth.strategy'].options[:client_id] = current_user.facebook_app_id
      request.env['omniauth.strategy'].options[:client_secret] = current_user.facebook_app_secret
      render plain: 'Omniauth setup phase.', status: 404
    end

   def facebook
     temp_access_token = omniauth_params['token']
     app_id            = current_user.facebook_app_id.presence || ENV['FACEBOOK_APP_ID']
     app_secret        = current_user.facebook_app_secret.presence || ENV['FACEBOOK_APP_SECRET']
     oauth             = Koala::Facebook::OAuth.new(app_id, app_secret)
     token             = oauth.exchange_access_token_info(temp_access_token)

     current_user.update(access_token: token['access_token'],
                         access_token_expires_at: DateTime.current + token['expires_in'].to_i.seconds)

     redirect_to select_page_admin_calendars_path(calendar_id: request_params['calendar_id'])
   end

   def failure
    redirect_to admin_calendars_path
   end

   private

   def omniauth_params
     request.env['omniauth.auth']['credentials']
   end

   def request_params
     request.env['omniauth.params']
   end
  end
end
