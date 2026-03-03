# frozen_string_literal: true

class Views::Admin::Articles::Form < Views::Admin::Base
  prop :article, Article, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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

  def render_new_layout(form) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        render Views::Admin::Articles::FormTabText.new(form: form)
      end
    end

    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        SectionHeader(
          title: 'Image',
          description: 'Image will be cropped to 16:9 ratio.',
          margin: 4
        )
        render Views::Admin::Articles::FormTabImage.new(form: form)
      end
    end

    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        SectionHeader(
          title: 'References',
          description: 'Link this article to partners and partnerships.',
          margin: 4
        )
        render Views::Admin::Articles::FormTabReferences.new(form: form)
      end
    end

    SaveBar() do
      raw form.submit(t('admin.actions.save'), class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange')
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
    )
  end
end
