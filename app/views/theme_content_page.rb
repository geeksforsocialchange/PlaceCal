# frozen_string_literal: true

# Base for a theme's markdown content pages (About, Privacy); usage is in doc/extensions.md.
class Views::ThemeContentPage < Views::Base
  prop :site, ::Site, reader: :private

  # Explicit so tables and heading ids survive; nothing that executes or loads is allowed.
  MARKDOWN_TAGS = %w[
    h1 h2 h3 h4 h5 h6
    p br hr div span
    strong em b i u s del ins mark small sub sup abbr code pre kbd samp var
    a img figure figcaption
    ul ol li dl dt dd
    blockquote cite q
    table caption colgroup col thead tbody tfoot tr th td
  ].freeze

  MARKDOWN_ATTRIBUTES = %w[
    href src alt title id class lang dir
    colspan rowspan scope headers
    start reversed value
    width height loading
    datetime cite
  ].freeze

  # Not h1: the page renders its own.
  HEADING_LEVELS = %i[h2 h3 h4 h5 h6].freeze

  # Built at load, not lazily, so two threads on the first request can't each make one.
  @markdown_cache = {}

  class << self
    attr_reader :markdown_cache

    def content_root(path = nil)
      return @content_root ||= inherited_setting(:content_root) if path.nil?

      @content_root = Pathname(path)
    end

    def slug(value = nil)
      return @slug ||= inherited_setting(:slug) if value.nil?

      @slug = value.to_s
    end

    def title(key = nil)
      return @title ||= inherited_setting(:title) if key.nil?

      @title = key.to_s
    end

    # Without one the layout's default meta description stays.
    def description(key = nil)
      return @description ||= inherited_setting(:description) if key.nil?

      @description = key.to_s
    end

    def markdown(relative_path, heading: nil, heading_level: :h2)
      # Fails at boot rather than as a 500 on first request.
      unless HEADING_LEVELS.include?(heading_level)
        raise ArgumentError,
              "heading_level #{heading_level.inspect} is not one of #{HEADING_LEVELS.join(', ')}"
      end

      sections << { path: relative_path.to_s, heading: heading&.to_s, heading_level: }
    end

    def sections
      @sections ||= inherited_setting(:sections)&.dup || []
    end

    # A missing file logs once and renders nothing rather than 500ing the page.
    def markdown_html(content_root, relative_path)
      path = Pathname(content_root).join(relative_path)
      cache = Views::ThemeContentPage.markdown_cache
      key = cache_key(path)
      return cache[key] if cache.key?(key)

      cache[key] = begin
        render_markdown(path.read)
      rescue Errno::ENOENT
        Rails.logger.warn("Theme content file missing, skipping block: #{path}")
        ''
      end
    end

    private

    # Keyed on mtime only in development, so edits show without a restart.
    def cache_key(path)
      return path.to_s unless Rails.env.local?

      [path.to_s, File.mtime(path)]
    rescue Errno::ENOENT
      path.to_s
    end

    def render_markdown(markdown)
      Rails::HTML5::SafeListSanitizer.new.sanitize(
        Kramdown::Document.new(markdown).to_html,
        tags: MARKDOWN_TAGS,
        attributes: MARKDOWN_ATTRIBUTES
      )
    end

    def inherited_setting(name)
      superclass.respond_to?(name) ? superclass.public_send(name) : nil
    end
  end

  def view_template
    content_for(:title) { page_title }
    content_for(:description) { page_description } if page_description

    div(class: "container-public py-8 page page--#{page_slug}", data: { page_slug: }) do
      h1(class: 'h1') { page_title }
      page_content
    end
  end

  private

  def page_slug
    self.class.slug || raise(NotImplementedError, "#{self.class} declares no slug")
  end

  def page_title
    key = self.class.title || raise(NotImplementedError, "#{self.class} declares no title")
    t(key)
  end

  def page_description
    key = self.class.description
    t(key) if key
  end

  # Override for a page laid out in its own sections rather than one markdown column.
  def page_content
    div(class: 'markdown-content max-w-(--width-prose-lg) text-base leading-relaxed') do
      page_body
    end
  end

  # Override for a page that needs more than headings and markdown blocks.
  def page_body
    self.class.sections.each do |section|
      send(section[:heading_level]) { t(section[:heading]) } if section[:heading]
      markdown(section[:path])
    end
  end

  def markdown(relative_path)
    root = self.class.content_root || raise(NotImplementedError, "#{self.class} declares no content_root")
    raw safe(Views::ThemeContentPage.markdown_html(root, relative_path))
  end
end
