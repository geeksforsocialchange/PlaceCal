# frozen_string_literal: true

class Views::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::Tag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::CSRFMetaTags

  if Rails.env.development?
    def before_template
      comment { self.class.name.to_s }
      super
    end
  end
end
