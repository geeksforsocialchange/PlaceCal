class RemoveOldNeighbourhoodProperties < ActiveRecord::Migration[6.0]
  def up
    change_table :neighbourhoods, bulk: true do |t|
      t.remove :ward,
               :district,
               :county,
               :region,
               :WD19CD,
               :WD19NM,
               :LAD19CD,
               :LAD19NM,
               :CTY19CD,
               :CTY19NM,
               :RGN19CD,
               :RGN19NM
    end
  end

  def down
    errors = []
    puts 'WARNING: Downgrade path has NOT been verified and should be manually verified first.'
    change_table :neighbourhoods, bulk: true do |t|
      t.column :ward,     :string, default: ''
      t.column :district, :string, default: ''
      t.column :county,   :string, default: ''
      t.column :region,   :string, default: ''
      t.column :WD19CD,   :string, default: ''
      t.column :WD19NM,   :string, default: ''
      t.column :LAD19CD,  :string, default: ''
      t.column :LAD19NM,  :string, default: ''
      t.column :CTY19CD,  :string, default: ''
      t.column :CTY19NM,  :string, default: ''
      t.column :RGN19CD,  :string, default: ''
      t.column :RGN19NM,  :string, default: ''
    end

    Neighbourhood.find_each do |ward|
      begin
        next if ward.unit != 'ward'

        puts "Filling ward #{ward.name} with parental information"

        ward.ward = ward.name
        ward.WD19CD = ward.unit_code_value
        ward.WD19NM = ward.unit_name
        if ward.parent
          ward.district = ward.parent.name if ward.parent
          ward.LAD19CD = ward.parent.unit_code_value
          ward.LAD19NM = ward.parent.name
        end
        if ward.parent.parent
          ward.county = ward.parent.parent.name if ward.parent.parent
          ward.CTY19CD = ward.parent.parent.unit_code_value
          ward.CTY19NM = ward.parent.parent.name
        end
        if ward.parent.parent.parent
          ward.region = ward.parent.parent.parent.name if ward.parent.parent.parent
          ward.RGN19CD = ward.parent.parent.parent.unit_code_value
          ward.RGN19NM = ward.parent.parent.parent.name
        end
      rescue => e
        errors << { error: e.message,
                    trace: e.backtrace_locations,
                    id: ward.id,
                    name: ward.name }
      end
    end

    return unless errors.any?

    File.open('20211118162518_remove_old_neighbourhood_properties.errors.txt', 'w') do |f|
      f.write errors
    end
  end
end
