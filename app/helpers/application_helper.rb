module ApplicationHelper
  def markdown(source)
    if source
      auto_link Kramdown::Document.new(source).to_html.html_safe
    else
      ''
    end
  end
end
