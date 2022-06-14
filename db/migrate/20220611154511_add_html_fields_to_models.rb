class AddHtmlFieldsToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :articles,               :body_html, :string
    add_column :events,          :description_html, :string
    add_column :events,              :summary_html, :string
    add_column :partners,        :description_html, :string
    add_column :partners,            :summary_html, :string
    add_column :partners, :accessibility_info_html, :string
    add_column :sites,           :description_html, :string
  end
end
