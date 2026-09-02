# frozen_string_literal: true

class Views::Admin::Pages::Index < Views::Admin::Base
  prop :pages, _Interface(:each), reader: :private

  def view_template
    heading = Page.model_name.human(count: 2)
    content_for(:title) { heading }

    div(class: 'flex items-center justify-between mb-6') do
      h1(class: 'text-2xl font-semibold') { heading }
      render_add_button
    end

    if pages.any?
      render_table
    else
      EmptyState(
        icon: :clipboard,
        message: t('admin.empty.no_items', items: Page.model_name.human(count: 2).downcase),
        hint: t('admin.pages.index.empty_hint')
      )
    end
  end

  private

  def render_add_button
    return unless policy(Page).create?

    link_to(new_admin_page_path, class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange') do
      icon(:plus, size: '4')
      plain t('admin.actions.add_model', model: Page.model_name.human)
    end
  end

  def render_table
    div(class: 'card bg-base-100 border border-base-300 shadow-sm overflow-x-auto') do
      table(class: 'table') do
        thead do
          tr do
            th { attr_label(:page, :title) }
            th { Site.model_name.human }
            th { attr_label(:page, :slug) }
            th { t('admin.pages.table.in_nav') }
            th { t('admin.table.status') }
            th { t('admin.labels.actions') }
          end
        end
        tbody do
          pages.each { |page| render_row(page) }
        end
      end
    end
  end

  def render_row(page)
    tr do
      td(class: 'font-medium') { link_to page.title, edit_admin_page_path(page), class: 'link' }
      td { page.site.name }
      td { code(class: 'font-mono text-sm') { "/#{page.slug}" } }
      td { page.show_in_nav ? t('admin.labels.yes') : t('admin.labels.no') }
      td { page.is_published ? t('admin.pages.status.published') : t('admin.pages.status.draft') }
      td { link_to t('admin.actions.edit'), edit_admin_page_path(page), class: 'link' }
    end
  end
end
