# frozen_string_literal: true

module HtmlRenderCache
  extend ActiveSupport::Concern

  included do
    def self.html_render_cache(field_name)
      html_fields << field_name
    end

    def self.html_fields
      @html_fiels ||= []
    end

    before_save :render_html_fields
  end

  def force_html_generation!
    @force_html_generation = true
  end

  private

  def render_html_fields
    self.class.html_fields.each do |field_name|
      cache_name = "#{field_name}_html".to_sym

      if changed.include?(field_name.to_s)
        value = changes[field_name.to_s][1]
        self[cache_name] = markdown_to_safe_html(value)
        next
      end

      next unless @force_html_generation

      value = attributes[field_name.to_s].to_s
      self[cache_name] = markdown_to_safe_html(value)
    end
  end

  def markdown_to_safe_html(value)
    html = Kramdown::Document.new(value).to_html
    sanitize_html(html)
  end

  def sanitize_html(html)
    Rails::HTML5::SafeListSanitizer.new.sanitize(html)
  end
end
