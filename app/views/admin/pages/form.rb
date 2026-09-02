# frozen_string_literal: true

class Views::Admin::Pages::Form < Views::Admin::Base
  prop :page, Page, reader: :private
  prop :sites, _Interface(:each), reader: :private

  def view_template
    simple_form_for([:admin, page], html: { class: 'space-y-6' }) do |form|
      Error(page)

      div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
        div(class: 'card-body p-6 space-y-4') do
          SectionHeader(
            title: t('admin.pages.sections.content'),
            description: t('admin.pages.sections.content_description'),
            margin: 4
          )
          render_site_field(form)
          render_title_field(form)
          render_slug_field(form)
          render_body_field(form)
        end
      end

      div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
        div(class: 'card-body p-6 space-y-4') do
          SectionHeader(
            title: t('admin.sections.publishing'),
            description: t('admin.pages.sections.publishing_description'),
            margin: 4
          )
          render_publishing_fields(form)
        end
      end

      render_danger_zone

      SaveBar() do
        raw form.submit(t('admin.actions.save'),
                        class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange')
      end
    end
  end

  private

  # Root and editors pick from every site. A site admin cannot submit site_id
  # (PagePolicy#permitted_attributes), so their page keeps a hidden field when
  # they only administer one site; with more than one they still choose, and
  # the controller resolves the choice against the sites they administer.
  def render_site_field(form)
    unless sites.many? || policy(page).permitted_attributes.include?(:site_id)
      raw form.hidden_field(:site_id)
      return
    end

    fieldset(class: 'fieldset') do
      raw form.label(:site_id, Site.model_name.human, class: 'fieldset-legend')
      raw form.select(
        :site_id,
        sites.map { |site| [site.name, site.id] },
        { include_blank: t('admin.placeholders.select_model', model: Site.model_name.human.downcase) },
        { class: 'select select-bordered w-full' }
      )
    end
  end

  def render_title_field(form)
    fieldset(class: 'fieldset') do
      raw form.label(:title, attr_label(:page, :title), class: 'fieldset-legend')
      raw form.input_field(:title, as: :string, class: 'input input-bordered w-full')
    end
  end

  def render_slug_field(form)
    fieldset(class: 'fieldset') do
      raw form.label(:slug, attr_label(:page, :slug), class: 'fieldset-legend')
      raw form.input_field(:slug, as: :string, class: 'input input-bordered w-full')
      p(class: 'label text-xs text-gray-600') { t('admin.pages.hints.slug') }
    end
  end

  def render_body_field(form)
    fieldset(class: 'fieldset') do
      raw form.label(:body, attr_label(:page, :body), class: 'fieldset-legend')
      raw form.text_area(:body, rows: 18, class: 'textarea textarea-bordered w-full font-mono')
      p(class: 'label text-xs text-gray-600') { t('admin.pages.hints.body') }
    end
  end

  def render_publishing_fields(form)
    fieldset(class: 'fieldset') do
      raw form.input(:is_published, wrapper: :tw_boolean, as: :boolean,
                                    label: t('admin.pages.fields.is_published'))
      raw form.input(:show_in_nav, wrapper: :tw_boolean, as: :boolean,
                                   label: t('admin.pages.fields.show_in_nav'))
    end

    fieldset(class: 'fieldset') do
      raw form.label(:position, attr_label(:page, :position), class: 'fieldset-legend')
      raw form.number_field(:position, class: 'input input-bordered w-full max-w-xs')
      p(class: 'label text-xs text-gray-600') { t('admin.pages.hints.position') }
    end
  end

  def render_danger_zone
    return if page.new_record?
    return unless policy(page).destroy?

    DangerZone(
      title: t('admin.actions.delete_model', model: Page.model_name.human),
      description: t('admin.danger_zone.delete_description', model: Page.model_name.human.downcase),
      button_text: t('admin.actions.delete_model', model: Page.model_name.human),
      button_path: admin_page_path(page),
      confirm: t('admin.confirm.delete_permanent', model: Page.model_name.human.downcase)
    )
  end
end
