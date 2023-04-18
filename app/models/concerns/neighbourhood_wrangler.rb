# frozen_string_literal: true

# This does all the neighbourhood saving and restoring
# called from the rake tasks
#    rails placecal:save_neighbourhoods
#    rails placecal:restore_neighbourhoods

class NeighbourhoodWrangler
  def extract_neighbourhood_children(neighbourhood)
    @count += 1
    STDOUT.print "\r#{@count} (#{neighbourhood.id})              "    
    STDOUT.flush
    
    {
      name: neighbourhood.name,
      name_abbr: neighbourhood.name_abbr.to_s,
      
      unit: neighbourhood.unit,
      unit_code_key: neighbourhood.unit_code_key,
      unit_code_value: neighbourhood.unit_code_value,
      unit_name: neighbourhood.unit_name,

      site_ids: neighbourhood.sites.pluck(:id),
      user_ids: neighbourhood.users.pluck(:id),
      partner_ids: neighbourhood.service_areas.pluck(:partner_id),
      
      postcodes: neighbourhood.addresses.select(&:postcode).map { |adr| adr.postcode.to_s.strip }.uniq,
      children: neighbourhood.children.map { |nh| extract_neighbourhood_children nh }
    }
  end

  def save_neighbourhoods
    @count = 0
    STDOUT.puts 'Saving to neighbourhoods.json'
    STDOUT.puts "#{Neighbourhood.count} neighbourhoods"

    output = Neighbourhood.roots.map { |nh| extract_neighbourhood_children nh }

    File.write('dump/neighbourhoods.json', output.to_json)
    
    STDOUT.puts "\ndone!"
    STDOUT.puts "written to dump/neighbourhoods.json"
  end

  #
  # restoration code
  #

  def restore_neighbourhood(node, parent = nil)
    
    neighbourhood = Neighbourhood.new(
      name: node['name'],
      name_abbr: node['name_abbr'],
      
      unit: node['unit'],
      unit_code_key: node['unit_code_key'],
      unit_code_value: node['unit_code_value'],
      unit_name: node['unit_name']
    )

    neighbourhood.parent = parent
    
    sites = Site.where(id: node['site_ids']).all
    sites.each do |site|
      neighbourhood.sites_neighbourhoods.new(site: site)
    end

    users = User.where(id: node['user_ids']).all
    users.each do |user|
      neighbourhood.neighbourhoods_users.new(user: user)
    end

    partners = Partner.where(id: node['partner_ids']).all
    partners.each do |partner|
      neighbourhood.service_areas.new partner: partner
    end
    
    neighbourhood.save!
    node['children'].each do |child|
      restore_neighbourhood child, neighbourhood
    end
    
    neighbourhood
  end
  
  def restore_neighbourhoods
    payload = JSON.parse(File.open('dump/neighbourhoods.json').read)
    root = payload.first
    
    root['children'].each do |child|
      restore_neighbourhood child
    end
  end
end
