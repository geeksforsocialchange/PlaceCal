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

  def admin_nav_link(name, path, icon = false)
    content_tag :li, class: 'nav-item' do
      klass = current_page?(path) ? 'nav-link active' : 'nav-link'
      if icon
        link_to "<i class='fa fa-#{icon} feather'></i> #{name}".html_safe, path, class: klass
      else
        link_to name, path, class: klass
      end
    end
  end
end
