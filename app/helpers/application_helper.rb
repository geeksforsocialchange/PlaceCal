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
  def user_policy
    UserPolicy.new(current_user, nil)
  end

  def admin_nav_link(name, path, icon = false)
    content_tag :li do
      base_classes = 'flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors'
      active_classes = 'bg-placecal-orange text-white'
      inactive_classes = 'text-gray-700 hover:bg-gray-200'
      klass = current_page?(path) ? "#{base_classes} #{active_classes}" : "#{base_classes} #{inactive_classes}"
      if icon
        link_to "<i class='fa fa-#{icon} w-4'></i> #{name}".html_safe, path, class: klass
      else
        link_to name, path, class: klass
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
  COLUMN_ICONS = {
    calendar: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z',
    users: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
    tag: 'M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z'
  }.freeze

  def icon_column_header(icon_name, tooltip)
    path = COLUMN_ICONS[icon_name.to_sym]
    return tooltip unless path

    content_tag(:span, title: tooltip) do
      content_tag(:svg, class: 'w-4 h-4', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24') do
        tag.path(d: path, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2')
      end
    end
  end

  # ported from https://github.com/comfy/active_link_to/blob/master/lib/active_link_to/active_link_to.rb
  def active_link_to(title, url, data: nil)
    current_path = request.original_fullpath
    link_path = Addressable::URI.parse(url).path
    is_current_path = current_path.match(%r{^#{Regexp.escape(link_path)}/?(\?.*)?$}).present?

    options = {}
    options[:data] = data if data.present?

    if is_current_path # current_path == link_path
      options[:class] = 'active'
      options['aria-current'] = 'page'
    end

    link_to(title, url, options).html_safe
  end
end
