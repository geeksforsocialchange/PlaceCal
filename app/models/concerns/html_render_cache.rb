
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
        html = Kramdown::Document.new(value).to_html
        write_attribute cache_name, html
        next
      end

      # puts attributes.to_json

      if @force_html_generation
        value = attributes[field_name.to_s].to_s
        html = Kramdown::Document.new(value).to_html
        write_attribute cache_name, html
      end
    end
  end
end
