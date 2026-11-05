# frozen_string_literal: true

class Views::Admin::Sites::FormTabBasic < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    site = form.object

    SectionHeader(
      title: t('admin.sections.basic_information'),
      description: t('admin.sites.sections.basic_info_description')
    )

    div(class: 'max-w-2xl space-y-4') do
      render_name_field
      render_site_admin_field(site)
      render_place_name_field
      render_contact_email_field
      render_tagline_field
      render_hero_text_field
      render_description_field
    end
  end

  private

  def render_name_field
    Field(for: form.field_id(:name), label: "#{Site.model_name.human} #{attr_label(:site, :name)}", required: true) do |f|
      raw form.input_field(:name, class: 'input input-bordered w-full', **f.aria)
    end
  end

  def render_site_admin_field(site)
    if policy(site).permitted_attributes.include?(:site_admin_id)
      render_editable_admin_field
    else
      render_readonly_admin_field(site)
    end
  end

  def render_editable_admin_field
    Field(for: form.field_id(:site_admin_id), label: t('admin.sites.fields.site_admin')) do
      raw form.select(:site_admin_id,
                      User.order(:last_name, :first_name).map { |u| [u.display_name, u.id] },
                      { include_blank: t('admin.placeholders.select_model', model: t('admin.models.admin.one').downcase) },
                      { class: 'select select-bordered w-full', 'aria-label': t('admin.sites.fields.site_admin'), data: { controller: 'tom-select' } })
    end
  end

  def render_readonly_admin_field(site)
    admin = site.site_admin
    admin_display = admin ? admin.display_name : t('admin.labels.none')

    div(class: 'card bg-base-200/50 border border-base-300 p-3') do
      p(class: 'text-sm') do
        strong { "#{t('admin.models.admin.one')}:" }
        plain " #{admin_display}"
      end
    end
  end

  def render_place_name_field
    Field(for: form.field_id(:place_name), label: attr_label(:site, :place_name), hint: t('admin.sites.fields.place_name_hint')) do |f|
      raw form.input_field(:place_name, class: 'input input-bordered w-full', **f.aria)
    end
  end

  def render_contact_email_field
    Field(for: form.field_id(:contact_email), label: attr_label(:site, :contact_email),
          hint: t('admin.sites.fields.contact_email_hint')) do |f|
      raw form.input_field(:contact_email, as: :email, class: 'input input-bordered w-full', **f.aria)
    end
  end

  def render_tagline_field
    Field(for: form.field_id(:tagline), label: attr_label(:site, :tagline)) do
      raw form.input_field(:tagline, class: 'input input-bordered w-full')
    end
  end

  def render_hero_text_field
    Field(for: form.field_id(:hero_text), label: attr_label(:site, :hero_text),
          hint: t('admin.sites.fields.hero_text_hint'), counter: 120) do |f|
      raw form.input_field(:hero_text, as: :text, class: 'textarea textarea-bordered w-full min-h-20', maxlength: 120, **f.aria,
                                       data: { controller: 'auto-expand', char_counter_target: 'input', action: 'input->char-counter#update' })
    end
  end

  def render_description_field
    Field(for: form.field_id(:description), label: attr_label(:site, :description)) do
      raw form.input_field(:description, as: :text,
                                         class: 'textarea textarea-bordered w-full min-h-32',
                                         data: { controller: 'auto-expand' })
    end
  end
end
