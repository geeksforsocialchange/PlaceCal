class FixAddressAndNeighbourhoodFields < ActiveRecord::Migration[6.1]
  def change
    Address.transaction do
      Address.all.each do |address|
        address.postcode = address.postcode
        address.save!
      end
    end

    Neighbourhood.transaction do
      Neighbourhood.all.each do |neighbourhood|
        neighbourhood.name_abbr = neighbourhood.name_abbr
        neighbourhood.save!
      end
    end
  end
end
