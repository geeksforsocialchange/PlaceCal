Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'],
    scope: 'pages_show_list',
    client_options: {
      site: 'https://graph.facebook.com/v3.0',
      authorize_url: "https://www.facebook.com/v3.0/dialog/oauth"
    },
    token_params: { parse: :json }
end
