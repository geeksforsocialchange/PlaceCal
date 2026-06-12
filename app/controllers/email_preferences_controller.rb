# frozen_string_literal: true

# Signed, no-login email preferences page (ADR 0015). Every outbound list
# email links here from its footer; the one-click endpoint backs the
# List-Unsubscribe-Post header (RFC 8058), which Gmail/Yahoo require.
class EmailPreferencesController < ApplicationController
  # The digest is quarterly, so links must outlive several editions — a
  # one-click unsubscribe that 410s is itself a deliverability problem.
  TOKEN_EXPIRY = 1.year
  TOKEN_PURPOSE = :email_preferences

  # Mail clients POST here directly with no session or CSRF token
  skip_before_action :verify_authenticity_token, only: [:one_click_unsubscribe]

  before_action :set_user_from_token

  def show
    render Views::EmailPreferences::Show.new(user: @user, token: params[:token])
  end

  def update
    EmailList.all.each do |list|
      subscribed = ActiveModel::Type::Boolean.new.cast(subscription_params[list.key])
      next if subscribed.nil?

      EmailSubscription.set(@user, list.key, subscribed, source: :unsubscribe_link)
    end

    flash[:success] = t('.saved')
    redirect_to email_preferences_path(token: params[:token])
  end

  # RFC 8058 one-click unsubscribe: unsubscribes from the single list named
  # in the link. Must succeed with no interaction beyond the POST.
  def one_click_unsubscribe
    list = EmailList.find(params[:list])
    return head :unprocessable_content if list.nil?

    EmailSubscription.set(@user, list.key, false, source: :unsubscribe_link)
    head :ok
  end

  # @param user [User]
  # @return [String] signed token for this user's preferences links
  def self.token_for(user)
    user.signed_id(purpose: TOKEN_PURPOSE, expires_in: TOKEN_EXPIRY)
  end

  private

  def set_user_from_token
    @user = User.find_signed(params[:token], purpose: TOKEN_PURPOSE)
    return if @user

    respond_to do |format|
      format.html { render Views::EmailPreferences::Expired.new, status: :gone }
      format.any { head :gone }
    end
  end

  def subscription_params
    params.fetch(:email_subscriptions, {}).permit(*EmailList.keys)
  end
end
