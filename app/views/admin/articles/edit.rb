# frozen_string_literal: true

class Views::Admin::Articles::Edit < Views::Admin::Base
  prop :article, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Article', title: article.title, id: article.id)
    raw(view_context.render('form'))
  end
end
