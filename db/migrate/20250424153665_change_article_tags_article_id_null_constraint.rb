# frozen_string_literal: true

class ChangeArticleTagsArticleIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :article_tags, :article_id, false
  end
end
