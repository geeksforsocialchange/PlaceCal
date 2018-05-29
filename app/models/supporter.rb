# frozen_string_literal: true

# app/models/supporter.rb
class Supporter < ApplicationRecord
  has_and_belongs_to_many :sites

  mount_uploader :logo, SupporterLogoUploader
end
