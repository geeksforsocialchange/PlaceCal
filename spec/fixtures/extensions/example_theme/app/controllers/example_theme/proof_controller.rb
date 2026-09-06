# frozen_string_literal: true

# Fixture-only controller. A real extension has no controllers: its homepage
# view is rendered by core's SitesController through the theme registry
# (WP 0.2). This route exists so WP 0.4 can prove engine loading before the
# registry exists.
class ExampleTheme::ProofController < ApplicationController
  before_action :set_site

  def show
    render ExampleTheme::Views::Home.new(site: @site)
  end
end
