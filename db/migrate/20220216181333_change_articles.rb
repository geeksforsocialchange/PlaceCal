class ChangeArticles < ActiveRecord::Migration[6.1]
  def change
    change_table :articles do |t|
      t.rename :description, :body
      t.rename :published, :published_at
      t.change :published_at, :datetime
    end
  end
end
