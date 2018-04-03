class AddColumnsToAdminPartners < ActiveRecord::Migration[5.1]
  def change
		add_column :partners, :partner_email, :string
		add_column :partners, :partner_name, :string
		add_column :partners, :partner_phone, :string
		add_column :partners, :calendar_email, :string
  	add_column :partners, :calendar_phone, :string
  	add_column :partners, :calendar_name, :string
  	add_column :partners, :public_name, :string
  end
end
