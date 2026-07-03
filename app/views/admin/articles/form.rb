# frozen_string_literal: true

class Views::Admin::Articles::Form < Views::Admin::Base
  prop :article, Article, reader: :private

  def view_template
    simple_form_for([:admin, article], html: { class: 'space-y-6', data: { controller: 'form-tabs live-validation', 'form-tabs-storage-key-value': 'articleTabAfterSave' } }) do |form|
      Error(article)

      if article.new_record?
        render_new_layout(form)
      else
        render_edit_layout(form)
      end
    end
  end

  private

  def render_new_layout(form)
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        render Views::Admin::Articles::FormTabText.new(form: form)
      end
    end

    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        SectionHeader(
          title: t('admin.articles.image.title'),
          description: t('admin.articles.image.description'),
          margin: 4
        )
        render Views::Admin::Articles::FormTabImage.new(form: form)
      end
    end

    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        SectionHeader(
          title: t('admin.articles.references.title'),
          description: t('admin.articles.references.description'),
          margin: 4
        )
        render Views::Admin::Articles::FormTabReferences.new(form: form)
      end
    end

    # Clear "save draft" vs "publish" actions instead of a checkbox buried in
    # a settings tab (issue #3308 Phase 4). The buttons submit is_draft; save
    # draft comes first so implicit (Enter-key) submission never publishes.
    SaveBar() do
      button(type: 'submit', name: 'article[is_draft]', value: 'true',
             class: 'btn bg-base-300 hover:bg-base-content/20 text-base-content border-base-300') do
        plain t('admin.articles.actions.save_draft')
      end
      button(type: 'submit', name: 'article[is_draft]', value: 'false',
             class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange') do
        plain t('admin.articles.actions.publish')
      end
    end
  end

  def render_edit_layout(form)
    TabForm(
      tabs: [
        { label: "\u{1F4DD} Text", hash: 'text', component: Views::Admin::Articles::FormTabText },
        { label: "\u{1F5BC}\u{FE0F} Image", hash: 'image', component: Views::Admin::Articles::FormTabImage },
        { label: "\u{1F517} References", hash: 'references', component: Views::Admin::Articles::FormTabReferences },
        { label: "\u{2699}\u{FE0F} Settings", hash: 'settings', component: Views::Admin::Articles::FormTabSettings, spacer_before: true }
      ],
      tab_name: 'article_tabs',
      storage_key: 'articleTabAfterSave',
      settings_hash: 'settings',
      form: form,
      record: article
    ) do
      render_publish_toggle
    end
  end

  # Publish/unpublish lives in the always-visible save bar rather than a
  # checkbox in the settings tab (issue #3308 Phase 4)
  def render_publish_toggle
    if article.is_draft
      button(type: 'submit', name: 'article[is_draft]', value: 'false',
             class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange',
             data: { action: 'click->save-bar#saveOnly' }) do
        plain t('admin.articles.actions.publish')
      end
    else
      button(type: 'submit', name: 'article[is_draft]', value: 'true',
             class: 'btn btn-ghost border border-base-300 text-base-content',
             data: { action: 'click->save-bar#saveOnly' }) do
        plain t('admin.articles.actions.unpublish')
      end
    end
  end
end
