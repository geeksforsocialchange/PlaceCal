# frozen_string_literal: true

class ArticleDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: 'Article.id', cond: :eq },
      title: { source: 'Article.title' },
      author: { source: 'Article.author' },
      partners: { source: 'Article.partners', orderable: false, searchable: false, cond: :null_value },
      published_at: { source: 'Article.published_at' },
      is_draft: { source: 'Article.is_draft' },
      updated_at: { source: 'Article.updated_at' }
    }
  end

  def data
    records.map do |record|
      {
        # apparently edit_admin_article_path doesn't exist????
        id: link_to(record.id, edit_admin_article_path(record)),
        title: link_to(record.title, edit_admin_article_path(record)),
        author: record.author,
        partners: record.partners.map(&:name),
        published_at: record.published_at,
        is_draft: record.is_draft,
        updated_at: record.updated_at
      }
    end
  end

  def get_raw_records
    # insert query here
    # User.all
    options[:articles]
  end
end
