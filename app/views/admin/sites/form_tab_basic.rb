# frozen_string_literal: true

class Views::Admin::Sites::FormTabBasic < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    site = form.object

    SectionHeader(
      title: t('admin.sections.basic_information'),
      description: t('admin.sites.sections.basic_info_description')
    )

    div(class: 'max-w-2xl space-y-4') do
      render_name_field
      render_site_admin_field(site)
      render_place_name_field
      render_tagline_field
      render_hero_text_field
      render_description_field
    end
  end

  private

  def render_name_field
    fieldset(class: 'fieldset') do
      raw form.label(:name, class: 'fieldset-legend') {
        "#{Site.model_name.human} #{attr_label(:site, :name)} " \
        "<span class=\"text-error\">#{t('admin.labels.required')}</span>".html_safe # rubocop:disable Rails/OutputSafety
      }
      raw form.input_field(:name, class: 'input input-bordered w-full')
    end
  end

  def render_site_admin_field(site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    if helpers.policy(site).permitted_attributes.include?(:site_admin_id)
      render_editable_admin_field
    else
      render_readonly_admin_field(site)
    end
  end

  def render_editable_admin_field # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    fieldset(class: 'fieldset') do
      raw form.label(:site_admin_id, t('admin.sites.fields.site_admin'), class: 'fieldset-legend')
      raw form.select(:site_admin_id,
                      User.order(:last_name, :first_name).map { |u|
                        full_name = [u.first_name, u.last_name].compact.join(' ').presence
                        label_text = full_name ? "#{full_name} (#{u.email})" : u.email
                        [label_text, u.id]
                      },
                      { include_blank: t('admin.placeholders.select_model', model: t('admin.models.admin.one').downcase) },
                      { class: 'select select-bordered w-full', 'aria-label': t('admin.sites.fields.site_admin'), data: { controller: 'tom-select' } })
    end
  end

  def render_readonly_admin_field(site) # rubocop:disable Metrics/AbcSize
    admin = site.site_admin
    admin_display = if admin
                      full_name = [admin.first_name, admin.last_name].compact.join(' ').presence
                      full_name ? "#{full_name} (#{admin.email})" : admin.email
                    else
                      t('admin.labels.none')
                    end

    div(class: 'card bg-base-200/50 border border-base-300 p-3') do
      p(class: 'text-sm') do
        strong { "#{t('admin.models.admin.one')}:" }
        plain " #{admin_display}"
      end
    end
  end

  def render_place_name_field
    fieldset(class: 'fieldset') do
      raw form.label(:place_name, attr_label(:site, :place_name), class: 'fieldset-legend')
      raw form.input_field(:place_name, class: 'input input-bordered w-full')
      p(class: 'fieldset-label') { t('admin.sites.fields.place_name_hint') }
    end
  end

  def render_tagline_field
    fieldset(class: 'fieldset') do
      raw form.label(:tagline, attr_label(:site, :tagline), class: 'fieldset-legend')
      raw form.input_field(:tagline, class: 'input input-bordered w-full')
    end
  end

  def render_hero_text_field # rubocop:disable Metrics/AbcSize
    fieldset(class: 'fieldset', data: { controller: 'char-counter', char_counter_max_value: '120' }) do
      raw form.label(:hero_text, attr_label(:site, :hero_text), class: 'fieldset-legend')
      raw form.input_field(:hero_text, as: :text,
                                       class: 'textarea textarea-bordered w-full min-h-20',
                                       maxlength: 120,
                                       data: { controller: 'auto-expand', char_counter_target: 'input', action: 'input->char-counter#update' })
      div(class: 'flex items-center justify-between mt-1') do
        p(class: 'fieldset-label') { t('admin.sites.fields.hero_text_hint') }
        span(class: 'text-xs tabular-nums transition-colors', data: { char_counter_target: 'counter' }) { '0 / 120' }
      end
    end
  end

  def render_description_field
    fieldset(class: 'fieldset') do
      raw form.label(:description, attr_label(:site, :description), class: 'fieldset-legend')
      raw form.input_field(:description, as: :text,
                                         class: 'textarea textarea-bordered w-full min-h-32',
                                         data: { controller: 'auto-expand' })
    end
  end
end
