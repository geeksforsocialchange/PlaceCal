# frozen_string_literal: true

class Views::Pages::ResourceNotFound < Views::Base
  def view_template
    div(class: 'py-8 pb-20 text-center [&_h1]:text-[4rem] [&_p]:text-[2rem]') do
      h1 { 'Not found' }
      p { 'The page you were looking for does not exist' }
    end
  end
end
