# frozen_string_literal: true

class StrongParametersFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &block)
    disabled = self.options[:disabled]
    display_filter = self.options[:display_only]&.collect { |attr| attr.is_a?(Hash) ? attr.keys : attr }&.flatten

    if disabled&.include?(attribute_name)
      options[:disabled] = true
      super
    elsif display_filter
      super if display_filter.include?(attribute_name)
    else
      super
    end
  end
end

module ApplicationHelper
  def user_policy
    UserPolicy.new(current_user, nil)
  end

  def admin_nav_link(name, path, icon = false)
    content_tag :li, class: 'nav-item' do
      klass = current_page?(path) ? 'nav-link active' : 'nav-link'
      if icon
        link_to "<i class='fa fa-#{icon} feather'></i> #{name}".html_safe, path, class: klass
      else
        link_to name, path, class: klass
      end
    end
  end

  def filtered_form_for(object, options = {}, &block)
    simple_form_for(object, options.merge(builder: StrongParametersFormBuilder), &block)
  end

  def has_any_global_admin_links?
    models = [User, Site, Neighbourhood, Article, Tag]

    models.any? { |model| policy(model).index? }
  end

  def image_uploader_hint(uploader_field)
    return if uploader_field.nil?

    format(
      'Supported file formats: %s. Max file size: %s',
      uploader_field.extension_allowlist.to_sentence,
      number_to_human_size(uploader_field.size_range.max)
    )
  end
end
