# frozen_string_literal: true

# Public landing for the partner verification invite (#3256 phase 5).
# Signed and no-login; like PartnerInfoConfirmationsController, the write
# happens on an explicit POST so link prefetchers can't false-verify.
# Verifying publishes the partner and writes the consent record.
class PartnerVerificationsController < ApplicationController
  TOKEN_EXPIRY = 30.days
  TOKEN_PURPOSE = :partner_verification

  before_action :set_partner_from_token

  def show
    render Views::PartnerVerifications::Show.new(partner: @partner, token: params[:token])
  end

  def create
    @partner.verify! unless @partner.verified_at

    render Views::PartnerVerifications::Verified.new(partner: @partner)
  end

  # @param partner [Partner]
  # @return [String] signed token for this partner's verification link
  def self.token_for(partner)
    partner.signed_id(purpose: TOKEN_PURPOSE, expires_in: TOKEN_EXPIRY)
  end

  private

  def set_partner_from_token
    @partner = Partner.find_signed(params[:token], purpose: TOKEN_PURPOSE)
    return if @partner

    render Views::EmailPreferences::Expired.new, status: :gone
  end
end
