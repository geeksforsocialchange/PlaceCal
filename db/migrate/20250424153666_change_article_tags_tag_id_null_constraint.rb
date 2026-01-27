# frozen_string_literal: true

class ChangeArticleTagsTagIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :article_tags, :tag_id, false
  end
end
