# frozen_string_literal: true

# A non-isolated engine draws straight into the host application's routes.
Rails.application.routes.draw do
  get "/example-theme-proof", to: "example_theme/proof#show", as: :example_theme_proof
end
