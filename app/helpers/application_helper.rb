# frozen_string_literal: true

class StrongParametersFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &)
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
  include SvgIconsHelper

  def user_policy
    UserPolicy.new(current_user, nil)
  end

  def admin_nav_link(name, path, icon_name = nil, root_only: false)
    content_tag :li do
      base_classes = 'flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors'
      # Use placecal-orange-dark for active state - provides 4.98:1 contrast ratio (WCAG AA compliant)
      active_classes = 'bg-placecal-orange-dark text-white'
      inactive_classes = 'text-gray-700 hover:bg-gray-200'
      klass = current_page?(path) ? "#{base_classes} #{active_classes}" : "#{base_classes} #{inactive_classes}"
      link_to path, class: klass do
        concat(icon(icon_name.to_sym, size: '4')) if icon_name
        concat(content_tag(:span, name, class: 'flex-1'))
        concat(icon(:crown, size: '3', css_class: 'text-amber-500')) if root_only
      end
    end
  end

  def filtered_form_for(object, options = {}, &)
    simple_form_for(object, options.merge(builder: StrongParametersFormBuilder), &)
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

  # Icon column header for datatables
  # Usage: icon_column_header(:calendar, 'Calendars')
  def icon_column_header(icon_name, tooltip)
    # Map legacy icon names to SvgIconsHelper names
    icon_map = { status: :check }
    mapped_name = icon_map[icon_name.to_sym] || icon_name.to_sym

    return tooltip unless SvgIconsHelper::ICONS.key?(mapped_name)

    content_tag(:span, title: tooltip) do
      icon(mapped_name, size: '4')
    end
  end

  # ported from https://github.com/comfy/active_link_to/blob/master/lib/active_link_to/active_link_to.rb
  # FIXME: I don't know how to include Literal so I can use _Nilable[String]
  def active_link_to(title, url, data: {}, base_css_class: '', active_css_class: 'active')
    current_path = request.original_fullpath
    link_path = Addressable::URI.parse(url).path
    is_current_path = current_section?(current_path, link_path)

    options = {}
    options[:data] = data if data.present?
    options[:class] = "#{base_css_class} #{active_css_class if is_current_path}"
    # "page" means this link points at the page being rendered. An ancestor
    # ("Events", underlined while an event page is open) is aria-current="true".
    options['aria-current'] = current_page_path?(current_path, link_path) ? 'page' : 'true' if is_current_path

    link_to(title, url, options).html_safe
  end

  # A nav link is current on its own page and on every page beneath it, so
  # "Events" stays underlined on an event page. The root link only matches
  # itself, otherwise it would be current everywhere.
  def current_section?(current_path, link_path)
    return false if link_path.blank?
    return current_path.match(%r{^/?(\?.*)?$}).present? if link_path == '/'

    current_path.match(%r{^#{Regexp.escape(link_path)}(/.*)?(\?.*)?$}).present?
  end

  # @return [Boolean] whether the link points at the page being rendered rather
  #   than at one of its ancestors
  def current_page_path?(current_path, link_path)
    current_path.match(%r{^#{Regexp.escape(link_path)}/?(\?.*)?$}).present?
  end

  # Convenience wrapper for humanized model names
  # Usage: human_model_name(Partner) => "Partner"
  # Usage: human_model_name(Partner, count: 2) => "Partners"
  def human_model_name(klass, count: 1)
    klass.model_name.human(count: count)
  end

  # Convenience wrapper for attribute labels from activerecord.attributes
  # Usage: attr_label(:partner, :name) => "Name"
  # Usage: attr_label(:calendar, :source) => "Source URL"
  def attr_label(model, attribute)
    I18n.t("activerecord.attributes.#{model}.#{attribute}", default: attribute.to_s.humanize)
  end
end
