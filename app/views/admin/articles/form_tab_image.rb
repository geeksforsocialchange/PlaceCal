# frozen_string_literal: true

class Views::Admin::Articles::FormTabImage < Views::Admin::Base
  prop :form, _Any, reader: :private

  def view_template
    div(class: 'max-w-2xl') do
      render Components::Admin::ImageUpload.new(
        form: form,
        attribute: :article_image,
        title: t('admin.articles.image.title'),
        aspect: '16:9'
      )
    end
  end
end
