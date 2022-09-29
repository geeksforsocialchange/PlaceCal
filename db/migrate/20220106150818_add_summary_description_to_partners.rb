class AddSummaryDescriptionToPartners < ActiveRecord::Migration[6.1]
  def up
    add_column :partners, :summary, :string
    add_column :partners, :description, :text

    Partner.find_each do |partner|
      next if partner.short_description.nil?

      summary, *description = partner.short_description.split("\r\n\r\n")
      partner.summary = summary
      partner.description = description.join("\r\n\r\n")
      partner.save(validate: false)
    end

    remove_column :partners, :short_description, :text
  end

  def down
    add_column :partners, :short_description, :text

    Partner.find_each do |partner|
      partner.short_description = "#{partner.summary}\r\n\r\n#{partner.description}"
      partner.save
    end

    remove_column :partners, :summary, :string
    remove_column :partners, :description, :text
  end
end
