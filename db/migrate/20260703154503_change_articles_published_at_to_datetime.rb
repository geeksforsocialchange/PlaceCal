# frozen_string_literal: true

# News v2 (issue #3308): published_at needs time-of-day precision so same-day
# posts have a defined order in feeds and "latest news" listings. Existing date
# values become midnight UTC. Indexed because every public listing orders by it.
class ChangeArticlesPublishedAtToDatetime < ActiveRecord::Migration[8.1]
  def up
    # safety_assured: articles is a small table (tens of rows in production),
    # so the type-change rewrite locks it only momentarily.
    safety_assured { change_column :articles, :published_at, :datetime }
  end

  def down
    safety_assured { change_column :articles, :published_at, :date }
  end
end
