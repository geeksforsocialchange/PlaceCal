# frozen_string_literal: true

class Views::Admin::Articles::FormTabSettings < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    article = form.object
    disabled_fields = policy(article).disabled_fields

    div(class: 'max-w-2xl space-y-8') do
      render_publishing_section(article, disabled_fields)
      render_danger_zone(article)
    end
  end

  private

  def render_publishing_section(article, disabled_fields)
    div(class: 'mb-8') do
      FormCard(
        icon: :newspaper,
        title: t('admin.sections.publishing'),
        description: 'Control when and if this article is visible on PlaceCal.'
      ) do
        fieldset(class: 'fieldset') do
          raw form.input(:is_draft, wrapper: :tw_boolean,
                                    as: :boolean,
                                    checked_value: false,
                                    unchecked_value: true,
                                    label: 'Publish this article')
        end

        if !article.new_record? && disabled_fields.exclude?(:published_at)
          fieldset(class: 'fieldset mt-4') do
            legend(class: 'fieldset-legend') { 'Publication Date' }
            raw form.date_field(:published_at, class: 'input input-bordered w-full max-w-xs')
          end
        end
      end
    end
  end

  def render_danger_zone(article)
    return if article.new_record?
    return unless policy(article).destroy?

    DangerZone(
      title: t('admin.actions.delete_model', model: Article.model_name.human),
      description: t('admin.danger_zone.delete_description', model: Article.model_name.human.downcase),
      button_text: t('admin.actions.delete_model', model: Article.model_name.human),
      button_path: admin_article_path(article),
      confirm: t('admin.confirm.delete_permanent', model: Article.model_name.human.downcase)
    )
  end
end
