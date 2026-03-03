# frozen_string_literal: true

class Views::Admin::Articles::New < Views::Admin::Base
  prop :article, Article, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Article', new_record: true)
    render Views::Admin::Articles::Form.new(article: article)
  end
end
