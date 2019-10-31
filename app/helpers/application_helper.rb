# frozen_string_literal: true

module ApplicationHelper
  def markdown(source)
    if source
      auto_link Kramdown::Document.new(source).to_html.html_safe do |text|
        truncate(text, length: 30)
      end
    else
      ''
    end
  end

  def user_policy
    UserPolicy.new(current_user, nil)
  end

  def admin_nav_link(name, path)
    klass = current_page?(path) ? 'active' : ''

    content_tag :li, class: klass do
      link_to name, path
    end
  end
end
