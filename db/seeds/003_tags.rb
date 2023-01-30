
module TagSeeder
  extend self

  def run
    tag = Tag.find_or_create_by!(name: 'Normal Tag') do |tag|
      tag.slug = 'normal-tag'
      tag.description = 'Description of the Normal Tag'
      tag.edit_permission = 'root'
      
    end
  end
end

TagSeeder.run
