# frozen_string_literal: true

class Views::Mailers::Base < Views::Base
  register_value_helper :greeting_text

  # Devise URL helpers (not standard route helpers, defined dynamically by Devise)
  register_value_helper :confirmation_url
  register_value_helper :edit_password_url
  register_value_helper :unlock_url
  register_value_helper :accept_invitation_url

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
