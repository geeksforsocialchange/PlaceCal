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
        description: status_hint(article)
      ) do
        render_status_line(article)

        if !article.new_record? && disabled_fields.exclude?(:published_at)
          fieldset(class: 'fieldset mt-4') do
            legend(class: 'fieldset-legend') { t('admin.articles.fields.published') }
            raw form.date_field(:published_at, class: 'input input-bordered w-full max-w-xs')
          end
        end
      end
    end
  end

  def status_hint(article)
    article.is_draft ? t('admin.articles.status.draft_hint') : t('admin.articles.status.published_hint')
  end

  def render_status_line(article)
    div(class: 'flex items-center gap-3') do
      if article.is_draft
        span(class: 'badge badge-ghost') { t('admin.articles.status.draft') }
      else
        span(class: 'badge badge-success') { t('admin.articles.status.published') }
        span(class: 'text-sm text-gray-600') { article.published_at.strftime('%-d %b %Y') } if article.published_at.present?
        a(href: live_article_path, target: '_blank', rel: 'noopener',
          class: 'link text-placecal-teal-dark text-sm') do
          plain t('admin.articles.actions.view_live')
        end
      end
    end
  end

  # The article on the nationwide directory, which shows every published
  # article — a link that works no matter which sites the partner is on
  def live_article_path
    article = form.object
    news_url(article, subdomain: false)
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
