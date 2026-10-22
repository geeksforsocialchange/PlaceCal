# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client IP behind Cloudflare", type: :request do
  it "is the visitor's address, not the Cloudflare edge or the local proxy" do
    get "/robots.txt", headers: { "X-Forwarded-For" => "203.0.113.7, 172.70.1.2" }, env: { "REMOTE_ADDR" => "172.18.0.5" }

    expect(request.remote_ip).to eq("203.0.113.7")
    expect(Rack::Attack.client_ip(Rack::Attack::Request.new(request.env))).to eq("203.0.113.7")
  end
end
