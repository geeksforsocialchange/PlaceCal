class GenerateNeighbourhoodsStructure < ActiveRecord::Migration[6.0]
  def change
    errors = []

    change_table(:neighbourhoods, bulk: true) do |n|
      n.add_column :unit,            :string, default: 'ward'
      n.add_column :unit_code_key,   :string, default: 'WD19CD'
      n.add_column :unit_code_value, :string
      n.add_column :unit_name,       :string
    end

    Neighbourhood.find_each do |ward|
      begin
        next if ward.unit != 'ward'

        # Nice variables
        district_name = ward.LAD19NM
        county_name = ward.CTY19NM

        # Fill ward with default values
        ward.unit_code_value = ward.WD19CD
        ward.unit_name = ward.name

        # Find/Create district and county neighbourhoods
        district_node = TreeNode.create_or_find_by!(name: district_name)
        county_node = TreeNode.create_or_find_by!(name: county_name)

        # Fill the district
        district_node.unit = 'district'
        district_node.unit_code_key = 'LAD19CD'
        district_node.unit_code_value = ward.LAD19CD
        district_node.unit_name = district_name

        # Fill the county
        county_node.unit = 'county'
        county_node.unit_code_key = 'CTY19CD'
        county_node.unit_code_value = ward.CTY19CD
        county_node.unit_name = county_name

        # Shove the district into the county's children
        country_node.children << district_node if county_node.children.none? district_node

        # Shove the ward into the county's children
        district_node.children << ward

      rescue => e
        errors << { error: e.message, id: neighbourhood.id, name: neighbournood.name }
        next
      end
    end

    system "echo #{errors} >> generate_neighbourhood_structure.errors.txt" if errors.any?
  end
end
