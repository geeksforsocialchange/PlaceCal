# frozen_string_literal: true

class Views::Mailers::Base < Views::Base
  def view_template
    doctype
    html do
      head do
        meta(charset: 'utf-8')
      end
      body { email_content }
    end
  end

  def email_content
    # Override in subclasses
  end
end
