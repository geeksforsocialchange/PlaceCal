# frozen_string_literal: true

# Unknown paths on the directory and local sites get the site's own not-found page.
class NotFoundController < ApplicationController
  def show
    resource_not_found
  end
end
