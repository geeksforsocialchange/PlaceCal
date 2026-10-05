# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
#
#  id          :bigint           not null, primary key
#  description :text
#  image       :string
#  name        :string
#  route       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "rails_helper"

RSpec.describe Collection do
  let(:collection) { create(:collection) }

  describe "#named_route" do
    it "returns named route if set" do
      expect(collection.named_route).to eq("/named-route")
    end

    it "returns default route if route is empty" do
      collection.update(route: "")
      expect(collection.named_route).to eq("/collections/#{collection.id}")
    end
  end
end
