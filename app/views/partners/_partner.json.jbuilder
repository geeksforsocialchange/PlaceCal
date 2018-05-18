# frozen_string_literal: true

json.extract! partner, :id, :created_at, :updated_at
json.url partner_url(partner, format: :json)
