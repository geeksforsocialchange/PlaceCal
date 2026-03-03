# frozen_string_literal: true

class Views::Admin::Sites::FormTabImages < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    site = form.object

    SectionHeader(
      title: t('admin.sections.images_theme'),
      description: t('admin.sites.sections.images_description')
    )

    render_theme_field(site)
    render_logo_fields(site)
    render_hero_image_field(site)
  end

  private

  def render_theme_field(site)
    return unless policy(site).permitted_attributes.include?(:theme)

    fieldset(class: 'fieldset max-w-xs mb-8') do
      legend(class: 'fieldset-legend') { attr_label(:site, :theme) }
      raw form.input_field(:theme, as: :select,
                                   collection: Site.theme.values.map { |v| [v.to_s.titleize, v] },
                                   class: 'select select-bordered w-full')
    end
  end

  def render_logo_fields(site)
    return unless policy(site).permitted_attributes.include?(:logo)

    div(class: 'grid grid-cols-1 md:grid-cols-2 gap-8 mb-8') do
      div do
        render_image_upload_field(
          legend_text: attr_label(:site, :logo),
          attribute: :logo,
          image_url: form.object.logo.url,
          hint_uploader: site.logo,
          preview_class: 'max-w-full max-h-32 rounded-lg border border-base-300'
        )
      end

      div do
        render_image_upload_field(
          legend_text: attr_label(:site, :footer_logo),
          attribute: :footer_logo,
          image_url: form.object.footer_logo.url,
          hint_uploader: site.footer_logo,
          preview_class: 'max-w-full max-h-24',
          preview_wrapper_class: 'bg-neutral p-4 rounded-lg inline-block'
        )
      end
    end
  end

  def render_image_upload_field(legend_text:, attribute:, image_url:, hint_uploader:, preview_class:, preview_wrapper_class: nil)
    fieldset(class: 'fieldset') do
      legend(class: 'fieldset-legend') { legend_text }
      div(data: { controller: 'image-preview' }) do
        render_upload_label(attribute, hint_uploader)
        if image_url
          if preview_wrapper_class
            div(class: preview_wrapper_class) do
              image_tag(image_url, class: preview_class, data: { image_preview_target: 'img' })
            end
          else
            image_tag(image_url, class: preview_class, data: { image_preview_target: 'img' })
          end
        end
      end
    end
  end

  def render_upload_label(attribute, hint_uploader)
    label(class: 'flex items-center gap-3 p-3 rounded-lg border-2 border-dashed border-base-300 hover:border-placecal-orange transition-colors cursor-pointer mb-3') do
      div(class: 'flex-shrink-0 w-10 h-10 rounded-lg bg-placecal-orange/10 flex items-center justify-center') do
        raw icon(:upload, size: '5', css_class: 'text-placecal-orange')
      end
      div(class: 'flex-1 min-w-0') do
        p(class: 'text-sm font-medium') { t('admin.images.choose_file') }
        p(class: 'text-xs text-gray-600') { image_uploader_hint(hint_uploader) }
      end
      raw form.input_field(attribute, as: :file, class: 'sr-only',
                                      data: { action: 'change->image-preview#file', image_preview_target: 'input' })
    end
  end

  def render_hero_image_field(site)
    fieldset(class: 'fieldset bg-base-200/50 border border-base-300 rounded-box p-4') do
      legend(class: 'fieldset-legend') { attr_label(:site, :hero_image) }
      p(class: 'text-sm text-gray-600 mb-4') do
        plain t('admin.sites.fields.hero_image_description')
        whitespace
        a(href: 'https://gfsc.notion.site/Homepage-Images-f0a19b7f8f5446948bc4601950c9a0a2',
          class: 'link link-hover text-placecal-orange', target: '_blank') { t('admin.sites.fields.hero_handbook_link') }
      end

      div(data: { controller: 'image-preview' }) do
        render_hero_upload_label(site)
        if form.object.hero_image.url
          image_tag(form.object.hero_image.url,
                    class: 'max-w-md rounded-lg border border-base-300 mb-4',
                    data: { image_preview_target: 'img' })
        end
      end

      render_hero_credit_fields
    end
  end

  def render_hero_upload_label(site)
    label(class: 'flex items-center gap-3 p-3 rounded-lg border-2 border-dashed border-base-300 hover:border-placecal-orange transition-colors cursor-pointer bg-base-100 mb-4') do
      div(class: 'flex-shrink-0 w-10 h-10 rounded-lg bg-placecal-orange/10 flex items-center justify-center') do
        raw icon(:upload, size: '5', css_class: 'text-placecal-orange')
      end
      div(class: 'flex-1 min-w-0') do
        p(class: 'text-sm font-medium') { t('admin.images.choose_file') }
        p(class: 'text-xs text-gray-600') { image_uploader_hint(site.hero_image) }
      end
      raw form.input_field(:hero_image, as: :file, class: 'sr-only',
                                        data: { action: 'change->image-preview#file', image_preview_target: 'input' })
    end
  end

  def render_hero_credit_fields
    div(class: 'grid grid-cols-1 md:grid-cols-2 gap-4') do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { attr_label(:site, :hero_image_credit) }
        raw form.input_field(:hero_image_credit, class: 'input input-bordered w-full input-sm bg-base-100')
        p(class: 'fieldset-label') { t('admin.sites.fields.image_credit_hint') }
      end

      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { attr_label(:site, :hero_image_alt) }
        raw form.input_field(:hero_alttext, class: 'input input-bordered w-full input-sm bg-base-100')
        p(class: 'fieldset-label') { t('admin.sites.fields.alt_text_hint') }
      end
    end
  end
end
