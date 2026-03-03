# frozen_string_literal: true

class Views::Admin::Sites::FormTabSettings < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    site = form.object

    render Components::Admin::SectionHeader.new(
      title: t('admin.sections.admin_settings'),
      description: t('admin.sites.sections.admin_description')
    )

    div(class: 'max-w-xl space-y-8') do
      render_publishing_status
      render_url_slug_fields(site)
      render_danger_zone(site)
    end
  end

  private

  def render_publishing_status
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { t('admin.sites.fields.publishing_status') }
      render Components::Admin::ToggleCard.new(
        form: form,
        attribute: :is_published,
        title: t('admin.sites.fields.published'),
        description: t('admin.sites.fields.published_hint')
      )
    end
  end

  def render_url_slug_fields(site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'grid grid-cols-1 md:grid-cols-2 gap-4') do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') do
          plain attr_label(:site, :url)
          whitespace
          span(class: 'text-error') { t('admin.labels.required') }
        end
        if helpers.policy(site).permitted_attributes.include?(:url)
          raw form.input_field(:url, class: 'input input-bordered w-full font-mono text-sm')
        else
          raw form.input_field(:url, class: 'input input-bordered w-full font-mono text-sm bg-base-200', disabled: true)
        end
      end

      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') do
          plain attr_label(:site, :slug)
          whitespace
          span(class: 'text-error') { t('admin.labels.required') }
        end
        if helpers.policy(site).permitted_attributes.include?(:slug)
          raw form.input_field(:slug, class: 'input input-bordered w-full font-mono text-sm')
        else
          raw form.input_field(:slug, class: 'input input-bordered w-full font-mono text-sm bg-base-200', disabled: true)
        end
      end
    end
  end

  def render_danger_zone(site)
    return if site.new_record?

    div(class: 'divider')

    render Components::Admin::DangerZone.new(
      title: t('admin.danger_zone.delete_title', model: Site.model_name.human),
      description: t('admin.danger_zone.delete_description', model: Site.model_name.human.downcase),
      button_text: t('admin.actions.delete_model', model: Site.model_name.human),
      button_path: helpers.admin_site_path(site),
      confirm: t('admin.confirm.delete_permanent', model: Site.model_name.human.downcase)
    )
  end
end
