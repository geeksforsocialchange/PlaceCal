# frozen_string_literal: true

class Views::Base < Phlex::HTML
  extend Literal::Properties
  include Components

  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::Tag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::Pluralize
  include Phlex::Rails::Helpers::NumberWithDelimiter
  include Phlex::Rails::Helpers::DistanceOfTimeInWords
  include Phlex::Rails::Helpers::ImageURL
  include Phlex::Rails::Helpers::Flash
  include Phlex::Rails::Helpers::Request
  include Phlex::Rails::Helpers::RadioButtonTag
  include Phlex::Rails::Helpers::LabelTag
  include Phlex::Rails::Helpers::HiddenFieldTag
  include Phlex::Rails::Helpers::DateFieldTag
  include Phlex::Rails::Helpers::FormTag
  include Phlex::Rails::Helpers::ContentTag
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::MailTo
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::Sanitize
  include Phlex::Rails::Helpers::Truncate
  include Phlex::Rails::Helpers::ControllerName

  register_value_helper :safe_join
  register_output_helper :active_link_to
  register_value_helper :next_url
  register_value_helper :current_user
  register_value_helper :policy

  # I18n translate helper
  def t(key, **)
    I18n.t(key, **)
  end

  if Rails.env.development?
    def before_template
      comment { self.class.name.to_s }
      super
    end
  end
end
