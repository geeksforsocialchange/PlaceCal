# frozen_string_literal: true

class Views::Admin::Components::Base < Views::Base
  include Views::Admin::Components::SvgIcons

  # I18n translate helper
  def t(key, **)
    I18n.t(key, **)
  end
end
