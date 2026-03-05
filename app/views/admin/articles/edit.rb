# frozen_string_literal: true

class Views::Admin::Articles::Edit < Views::Admin::Base
  prop :article, Article, reader: :private

  def view_template
    PageHeader(model_name: 'Article', title: article.title, id: article.id)
    render Views::Admin::Articles::Form.new(article: article)
  end
end
