# frozen_string_literal: true

class Views::Admin::Articles::FormTabText < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    article = form.object
    disabled_fields = policy(article).disabled_fields

    div(class: 'space-y-6') do
      render_details_section(article, disabled_fields)
      render_body_section
    end
  end

  private

  def render_details_section(article, disabled_fields)
    div(class: 'space-y-3') do
      h2(class: 'text-base font-semibold flex items-center gap-2') do
        raw icon(:edit, size: '4')
        plain t('admin.articles.sections.details')
      end

      div(class: 'space-y-4') do
        render_title_field
        render_author_and_date(article, disabled_fields)
      end
    end
  end

  def render_title_field
    fieldset(class: 'fieldset') do
      raw form.label(:title, class: 'fieldset-legend') {
        "#{attr_label(:article, :title)} <span class=\"text-error\">#{t('admin.labels.required')}</span>".html_safe
      }
      raw form.input_field(:title, as: :string, class: 'input input-bordered w-full text-xl font-semibold',
                                   id: 'article_title',
                                   placeholder: t('admin.articles.fields.title_placeholder'))
    end
  end

  def render_author_and_date(article, disabled_fields)
    div(class: 'flex flex-col sm:flex-row sm:items-end gap-4') do
      render_author_field(article, disabled_fields)
      render_publication_date(article) unless article.new_record?
    end
  end

  def render_author_field(article, disabled_fields)
    fieldset(class: 'fieldset min-w-64 article_author') do
      raw form.label(:author_id, attr_label(:article, :author), class: 'fieldset-legend')

      if disabled_fields.include?(:author_id)
        div(class: 'text-base-content font-medium') { article.author&.admin_name || 'Unknown' }
      else
        raw form.select(
          :author_id,
          User.order(:last_name, :first_name).map { |u| [u.admin_name, u.id] },
          { include_blank: t('admin.placeholders.select_model', model: attr_label(:article, :author).downcase) },
          {
            class: 'select select-bordered w-full',
            id: 'article_author_id',
            'aria-label': attr_label(:article, :author),
            data: { controller: 'tom-select' }
          }
        )
      end
    end
  end

  def render_publication_date(article)
    fieldset(class: 'fieldset w-auto') do
      legend(class: 'fieldset-legend') { t('admin.articles.fields.published') }
      div(class: 'input input-bordered h-9 flex items-center gap-2 bg-base-200/50 cursor-default') do
        raw icon(:calendar, size: '4', css_class: 'text-gray-600')

        if article.published_at.present?
          span(class: 'text-base-content') { article.published_at.strftime('%d %b %Y') }
          span(class: 'text-gray-600 text-sm') do
            plain "(#{t('admin.time.ago', time: time_ago_in_words(article.published_at))})"
          end
        else
          span(class: 'text-gray-600 italic') { t('admin.articles.fields.not_published') }
        end
      end
    end
  end

  def render_body_section
    div(data: { controller: 'markdown-preview' }) do
      raw form.label(:body, class: 'fieldset-legend') {
        "#{attr_label(:article, :body)} <span class=\"text-error\">#{t('admin.labels.required')}</span>".html_safe
      }

      p(class: 'text-sm text-gray-600 mb-3') do
        plain 'This field accepts '
        a(
          href: 'https://www.markdownguide.org/basic-syntax/',
          class: 'link underline text-placecal-teal-dark hover:no-underline',
          target: '_blank'
        ) { 'Markdown syntax' }
        plain '.'
      end

      render_markdown_header
      render_markdown_content
    end
  end

  def render_markdown_header
    div(class: 'flex items-center gap-0 mb-2', data: { markdown_preview_target: 'container' }) do
      div(class: 'flex-1 min-w-64 flex items-center justify-between', data: { markdown_preview_target: 'editorPane' }) do
        div(class: 'text-xs font-medium text-gray-600 flex items-center gap-1') do
          raw icon(:edit, size: '3')
          plain t('admin.articles.markdown.write')
        end

        render_markdown_toolbar
      end

      div(class: 'hidden lg:block w-4')

      div(class: 'hidden lg:flex flex-1 min-w-64 items-center', data: { markdown_preview_target: 'previewPane' }) do
        div(class: 'text-xs font-medium text-gray-600 flex items-center gap-1') do
          raw icon(:eye, size: '3')
          plain t('admin.articles.markdown.preview')
        end
      end
    end
  end

  def render_markdown_toolbar
    div(class: 'flex items-center gap-0.5', data: { markdown_preview_target: 'toolbar' }) do
      toolbar_button('click->markdown-preview#insertBold', t('admin.articles.markdown.toolbar.bold')) do
        strong { 'B' }
      end
      toolbar_button('click->markdown-preview#insertItalic', t('admin.articles.markdown.toolbar.italic')) do
        em { 'I' }
      end
      toolbar_button('click->markdown-preview#insertLink', t('admin.articles.markdown.toolbar.link')) do
        raw icon(:link, size: '4')
      end

      div(class: 'divider divider-horizontal mx-0.5 h-4')

      toolbar_button('click->markdown-preview#insertH2', t('admin.articles.markdown.toolbar.h2')) { 'H2' }
      toolbar_button('click->markdown-preview#insertH3', t('admin.articles.markdown.toolbar.h3')) { 'H3' }

      div(class: 'divider divider-horizontal mx-0.5 h-4')

      toolbar_button('click->markdown-preview#insertBulletList', t('admin.articles.markdown.toolbar.bullet_list')) do
        raw icon(:list, size: '4')
      end
      toolbar_button('click->markdown-preview#insertBlockquote', t('admin.articles.markdown.toolbar.blockquote')) do
        raw safe('&ldquo;')
      end
      toolbar_button('click->markdown-preview#insertCode', t('admin.articles.markdown.toolbar.code')) do
        code(class: 'text-xs') { raw safe('&lt;/&gt;') }
      end
    end
  end

  def toolbar_button(action, title, &)
    button(type: 'button', class: 'btn btn-ghost btn-xs px-2', data: { action: action }, title: title, &)
  end

  def render_markdown_content
    div(class: 'flex gap-0', data: { markdown_preview_target: 'contentContainer' }) do
      # Editor
      div(class: 'flex-1 min-w-64', data: { markdown_preview_target: 'editorContent' }) do
        raw form.input_field(
          :body, as: :text,
                 class: 'textarea textarea-bordered w-full min-h-96 font-mono text-sm resize-none',
                 data: {
                   controller: 'auto-expand',
                   markdown_preview_target: 'input',
                   action: 'input->markdown-preview#updatePreview keydown->markdown-preview#handleKeydown'
                 },
                 id: 'article_body'
        )
      end

      # Resizer handle
      div(
        class: 'hidden lg:flex w-4 cursor-col-resize items-center justify-center group hover:bg-base-200 transition-colors',
        data: { markdown_preview_target: 'resizer', action: 'mousedown->markdown-preview#startResize' }
      ) do
        div(class: 'w-1 h-8 rounded-full bg-base-300 group-hover:bg-placecal-orange transition-colors')
      end

      # Preview
      div(class: 'hidden lg:block flex-1 min-w-64', data: { markdown_preview_target: 'previewContent' }) do
        div(class: 'border border-base-300 rounded-lg px-6 py-2 min-h-96 bg-base-100 overflow-y-auto') do
          div(data: { markdown_preview_target: 'output' }, class: 'markdown-preview') do
            p(class: 'text-gray-500 italic') { t('admin.articles.markdown.preview_placeholder') }
          end
        end
      end
    end
  end
end
