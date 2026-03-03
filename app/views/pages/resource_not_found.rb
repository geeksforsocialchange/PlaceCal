# frozen_string_literal: true

class Views::Pages::ResourceNotFound < Views::Base
  def view_template
    div(id: 'not_found') do
      h1 { 'Not found' }
      p { 'The page you were looking for does not exist' }
    end
  end
end
