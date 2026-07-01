# frozen_string_literal: true

# Landing page for the digest's "confirm everything is up to date" button
# (#3256 phase 2). Signed and no-login like EmailPreferencesController; the
# write happens on an explicit POST rather than on the GET so link
# prefetchers (Outlook Safe Links etc.) can't record false confirmations.
class PartnerInfoConfirmationsController < ApplicationController
  TOKEN_EXPIRY = 1.year
  TOKEN_PURPOSE = :partner_info_confirmation
  SOURCE = 'digest_link'

  before_action :set_user_from_token

  def show
    render Views::PartnerInfoConfirmations::Show.new(user: @user, token: params[:token])
  end

  def create
    @user.partners.find_each do |partner|
      partner.confirm_information!(by: @user, source: SOURCE)
    end

    render Views::PartnerInfoConfirmations::Confirmed.new
  end

  # @param user [User]
  # @return [String] signed token for this user's confirm link
  def self.token_for(user)
    user.signed_id(purpose: TOKEN_PURPOSE, expires_in: TOKEN_EXPIRY)
  end

  private

  def set_user_from_token
    @user = User.find_signed(params[:token], purpose: TOKEN_PURPOSE)
    return if @user

    render Views::EmailPreferences::Expired.new, status: :gone
  end
end
