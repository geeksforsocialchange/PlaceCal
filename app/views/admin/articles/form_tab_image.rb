# frozen_string_literal: true

class Views::Admin::Articles::FormTabImage < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    div(class: 'max-w-2xl') do
      ImageUpload(
        form: form,
        attribute: :article_image,
        title: t('admin.articles.image.title'),
        aspect: '16:9'
      )
      render_credit_field
    end
  end

  private

  def render_credit_field
    fieldset(class: 'fieldset mt-3') do
      raw form.label(:image_credit, t('admin.articles.image.credit_label'), class: 'fieldset-legend')
      raw form.input_field(:image_credit, as: :string, class: 'input input-bordered w-full',
                                          placeholder: t('admin.articles.image.credit_placeholder'))
    end
  end
end
