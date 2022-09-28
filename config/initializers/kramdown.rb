# frozen_string_literal: true

# config/initializers/kramdown.rb

module Kramdown
  module Converter
    class Html
      include ActionView::Helpers::AssetTagHelper

      def convert_img(el, _indent)
        attrs = el.attr.dup
        link = attrs.delete "src"
        image_tag ActionController::Base.helpers.asset_path(link), attrs
      end
    end
  end
end
