# frozen_string_literal: true

# == Schema Information
#
# Table name: online_addresses
#
#  id         :bigint           not null, primary key
#  link_type  :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class OnlineAddress < ApplicationRecord
  # ==== Includes / Extends ====
  extend Enumerize

  # ==== Enums / Enumerize ====
  enumerize :link_type,
            in: %i[direct indirect],
            default: :indirect
  # link_type -- managed by enumerize, attribute declaration skipped

  # ==== Attributes ====
  attribute :url, :string

  # ==== Associations ====
  has_many :events, dependent: :nullify
end
