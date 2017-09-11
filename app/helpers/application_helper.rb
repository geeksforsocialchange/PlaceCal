module ApplicationHelper
  def markdown(source)
    if source
      Kramdown::Document.new(source).to_html.html_safe
    else
      ""
    end
  end
end
