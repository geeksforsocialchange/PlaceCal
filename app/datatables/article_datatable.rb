class ArticleDatatable < Datatable

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: 'Article.id', cond: :eq },
      title: { source: 'Article.title' },
      body: { source: 'Article.body' },
      published_at: { source: 'Article.published_at' },
      is_draft: { source: 'Article.is_draft' }
    }
  end

  def data
    records.map do |record|
      {
        # apparently edit_admin_article_path doesn't exist????
        id: link_to(record.id, edit_admin_article_path(record)),
        title: link_to(record.title, edit_admin_article_path(record)),
        body: record.body,
        published_at: record.published_at,
        is_draft: record.is_draft
      }
    end
  end

  def get_raw_records
    # insert query here
    # User.all
    options[:articles]
  end

end
