# frozen_string_literal: true

require_relative 'auth_common'

class Users::InvitationsController < Devise::InvitationsController
  include Users::AuthCommon

  before_action :set_site

  def new
    self.resource = invite_resource
    resource.class.invite_key_fields.each { |f| resource.send(:"#{f}=", params[f]) }
    render Views::Devise::Invitations::New.new
  end

  def edit
    set_minimum_password_length if respond_to?(:set_minimum_password_length, true)
    resource.invitation_token = params[:invitation_token]
    render Views::Devise::Invitations::Edit.new
  end
end
