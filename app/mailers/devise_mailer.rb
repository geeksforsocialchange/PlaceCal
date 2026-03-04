# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  helper MailerHelper

  def confirmation_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :confirmation_instructions, opts) do |format|
      format.html { render Views::Mailers::Devise::ConfirmationInstructions.new(resource: record, token: token) }
    end
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :reset_password_instructions, opts) do |format|
      format.html { render Views::Mailers::Devise::ResetPasswordInstructions.new(resource: record, token: token) }
    end
  end

  def password_change(record, opts = {})
    devise_mail(record, :password_change, opts) do |format|
      format.html { render Views::Mailers::Devise::PasswordChange.new(resource: record) }
    end
  end

  def email_changed(record, opts = {})
    devise_mail(record, :email_changed, opts) do |format|
      format.html { render Views::Mailers::Devise::EmailChanged.new(resource: record) }
    end
  end

  def unlock_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :unlock_instructions, opts) do |format|
      format.html { render Views::Mailers::Devise::UnlockInstructions.new(resource: record, token: token) }
    end
  end

  def invitation_instructions(record, token, opts = {})
    @token = token
    devise_mail(record, :invitation_instructions, opts) do |format|
      format.html { render Views::Mailers::Devise::InvitationInstructions.new(resource: record, token: token) }
      format.text { render Views::Mailers::Devise::InvitationInstructionsText.new(resource: record, token: token) }
    end
  end
end
