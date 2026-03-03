# frozen_string_literal: true

class Views::TextBase < Views::Base
  def view_template
    raw safe(text_content)
  end

  def text_content
    raise NotImplementedError
  end
end
