class CreateArticlePartners < ActiveRecord::Migration[6.1]
  def change
    create_table :article_partners do |t|
      t.belongs_to :article
      t.belongs_to :partner

      t.timestamps
    end
    add_index :article_partners, %i[article_id partner_id], unique: true
  end
end
