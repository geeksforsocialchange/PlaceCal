# frozen_string_literal: true

# Optional heading between a listing page's hero and its filters, for example
# "All partners" (#3368). Core ships the locale key empty, so nothing renders
# unless a theme overrides `<ns>.index.list_heading`.
class Components::ListHeading < Components::Base
  prop :text, _Nilable(String), :positional, default: nil

  def view_template
    return if @text.blank?

    h2(class: 'list-heading') { @text }
  end
end
