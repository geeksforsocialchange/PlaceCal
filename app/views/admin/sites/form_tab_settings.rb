# frozen_string_literal: true

class Views::Admin::Sites::FormTabSettings < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    site = form.object

    SectionHeader(
      title: t('admin.sections.admin_settings'),
      description: t('admin.sites.sections.admin_description')
    )

    div(class: 'max-w-xl space-y-8') do
      render_publishing_status
      render_domain_slug_fields(site)
      render_danger_zone(site)
    end
  end

  private

  def render_publishing_status
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { t('admin.sites.fields.publishing_status') }
      ToggleCard(
        form:,
        attribute: :is_published,
        title: t('admin.sites.fields.published'),
        description: t('admin.sites.fields.published_hint')
      )
    end
  end

  def render_domain_slug_fields(site)
    div(class: 'grid grid-cols-1 md:grid-cols-2 gap-4') do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { plain attr_label(:site, :domain) }
        if policy(site).permitted_attributes.include?(:domain)
          raw form.input_field(:domain, class: 'input input-bordered w-full font-mono text-sm', placeholder: t('admin.sites.fields.domain_placeholder'))
        else
          raw form.input_field(:domain, class: 'input input-bordered w-full font-mono text-sm bg-base-200', disabled: true)
        end
        p(class: 'fieldset-label whitespace-normal') { t('admin.sites.fields.domain_hint', subdomain: subdomain_host(site)) }
        render_domain_status(site)
      end

      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { plain attr_label(:site, :slug) }
        if policy(site).permitted_attributes.include?(:slug)
          raw form.input_field(:slug, class: 'input input-bordered w-full font-mono text-sm')
        else
          raw form.input_field(:slug, class: 'input input-bordered w-full font-mono text-sm bg-base-200', disabled: true)
        end
        p(class: 'fieldset-label') { t('admin.hints.leave_blank_to_autogenerate') }
      end
    end
  end

  # Reflects the saved domain, not one just typed into the form.
  def render_domain_status(site)
    domain = site.domain_in_database
    return if domain.blank?

    if PlaceCal::ServedHosts.current.include?(domain)
      p(class: 'fieldset-label whitespace-normal text-success') { t('admin.sites.fields.domain_served', domain:) }
    else
      p(class: 'fieldset-label whitespace-normal') do
        t('admin.sites.fields.domain_external', domain:, subdomain: subdomain_host(site))
      end
    end
  end

  def subdomain_host(site)
    slug = site.slug_in_database.presence || t('admin.sites.fields.slug_placeholder')
    Site.subdomain_url_for(slug).sub(%r{\Ahttps?://}, '')
  end

  def render_danger_zone(site)
    return if site.new_record?

    div(class: 'divider')

    DangerZone(
      title: t('admin.danger_zone.delete_title', model: Site.model_name.human),
      description: t('admin.danger_zone.delete_description', model: Site.model_name.human.downcase),
      button_text: t('admin.actions.delete_model', model: Site.model_name.human),
      button_path: admin_site_path(site),
      confirm: t('admin.confirm.delete_permanent', model: Site.model_name.human.downcase)
    )
  end
end
