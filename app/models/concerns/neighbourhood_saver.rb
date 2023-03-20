# frozen_string_literal: true

class NeighbourhoodSaver
  def self.extract_neighbourhood_children(neighbourhood)
    @count += 1
    # Rails.logger.debug { "\r#{@count} (#{neighbourhood.id})              " }
    # Rails.logger.flush

    out = {
      name: neighbourhood.name,
      unit: neighbourhood.unit,
      unit_code_key: neighbourhood.unit_code_key,
      unit_code_value: neighbourhood.unit_code_value,
      unit_name: neighbourhood.unit_name
    }

    out[:name_abbr] = neighbourhood.name_abbr if neighbourhood.name_abbr.present?
    out[:children] = neighbourhood.children.map { |nh| extract_neighbourhood_children nh } if neighbourhood.children.present?
    out[:postcodes] = neighbourhood.addresses.select(&:postcode).map { |adr| adr.postcode.to_s.strip }.uniq if neighbourhood.addresses.present?

    out
  end

  def self.run
    @count = 0
    # Rails.logger.debug 'Saving to neighbourhoods.json'
    # Rails.logger.debug { "#{Neighbourhood.count} neighbourhoods" }

    output = Neighbourhood.roots.map { |nh| extract_neighbourhood_children nh }

    File.write('neighbourhoods.json', output)

    # Rails.logger.debug "\ndone!"
  end
end
