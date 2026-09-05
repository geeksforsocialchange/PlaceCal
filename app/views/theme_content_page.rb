# frozen_string_literal: true

# Base for a theme's static content pages (#3368 WP 5.2).
#
# A theme's About, Privacy or Get involved copy is markdown in the extension's
# own content/ directory rather than rows in a database, so the text stays
# reviewable in diffs and ships with the theme. Core already owns the route
# (config/initializers/site_page_routes.rb) and the concept (`theme.page` in
# doc/extensions.md); this is the rendering, which is not theme-specific
# either: a markdown pipeline, a per-file cache and a wrapper element.
#
# A page is a slug, a title and a list of markdown files:
#
#   class MyExt::Views::About < Views::ThemeContentPage
#     content_root MyExt::Engine.root.join("content")
#     slug         "about"
#     title        "my_ext.about.title"
#     description  "my_ext.site.description"
#
#     markdown "about/main.md"
#     markdown "about/accessibility.md", heading: "my_ext.about.accessibility"
#   end
#
# Everything is inherited, so a theme with several pages can put `content_root`
# on an intermediate base class of its own and each page declares only what is
# its own. A page that wants more than headings and markdown blocks (an intro
# paragraph, a wrapper around each block) overrides #page_body.
#
# The markup is the markup the theme CSS selects on: the `page page--<slug>`
# wrapper carrying `data-page-slug`, and the `.markdown-content` column.
class Views::ThemeContentPage < Views::Base
  prop :site, ::Site, reader: :private

  # What a markdown content page may render. The sanitiser's own default list
  # has no table elements in it at all, so a markdown table arrived as loose
  # whitespace-separated words, and it drops `id`, so kramdown's auto heading
  # anchors -- the normal way to link within a long privacy policy -- did not
  # work. Both are ordinary things for a theme's About or Privacy copy to use,
  # so the list is explicit rather than inherited.
  #
  # Nothing here executes or loads: no script, style, iframe, object, embed or
  # form. href and src are still scrubbed for their protocol by the sanitiser.
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

  # Which heading elements a section may declare. Not h1: the page renders its
  # own, and a second one is a heading-order failure.
  HEADING_LEVELS = %i[h2 h3 h4 h5 h6].freeze

  # Rendered HTML per markdown file, shared by every page of every theme.
  # Initialised here rather than with `||=` at the first call, so two threads
  # racing the first request cannot each build a Hash and lose one's writes.
  @markdown_cache = {}

  class << self
    attr_reader :markdown_cache

    # @param path [String, Pathname, nil] the directory the markdown paths are
    #   relative to, normally `<Ext>::Engine.root.join("content")`
    # @return [Pathname, nil]
    def content_root(path = nil)
      return @content_root ||= inherited_setting(:content_root) if path.nil?

      @content_root = Pathname(path)
    end

    # @param value [String, Symbol, nil] the page's registered slug, which is
    #   also the `page--<slug>` class and the `data-page-slug` attribute
    # @return [String, nil]
    def slug(value = nil)
      return @slug ||= inherited_setting(:slug) if value.nil?

      @slug = value.to_s
    end

    # @param key [String, nil] locale key for the page title
    # @return [String, nil]
    def title(key = nil)
      return @title ||= inherited_setting(:title) if key.nil?

      @title = key.to_s
    end

    # @param key [String, nil] locale key for the meta description; without
    #   one the layout's own default stays in place
    # @return [String, nil]
    def description(key = nil)
      return @description ||= inherited_setting(:description) if key.nil?

      @description = key.to_s
    end

    # One markdown file, rendered in declaration order.
    #
    # @param relative_path [String] path under content_root
    # @param heading [String, nil] locale key for a heading before the block
    # @param heading_level [Symbol] which heading element to render it as
    def markdown(relative_path, heading: nil, heading_level: :h2)
      # Caught at declaration, which is boot, rather than as a NoMethodError
      # 500 the first time someone asks for the page.
      unless HEADING_LEVELS.include?(heading_level)
        raise ArgumentError,
              "heading_level #{heading_level.inspect} is not one of #{HEADING_LEVELS.join(', ')}"
      end

      sections << { path: relative_path.to_s, heading: heading&.to_s, heading_level: heading_level }
    end

    # @return [Array<Hash>] the declared sections, in declaration order
    def sections
      @sections ||= inherited_setting(:sections)&.dup || []
    end

    # Rendered HTML for one markdown file. A superseded entry is left behind
    # rather than evicted, which is bounded by the edits in one dev session.
    #
    # A content file can go missing between releases (renamed, or added and not
    # committed). One absent block must not take the whole page down with a
    # 500, so log it and render nothing for that block. The empty result is
    # cached like any other, so a permanently missing file logs once rather
    # than on every request for that page.
    #
    # @param content_root [Pathname]
    # @param relative_path [String]
    # @return [String]
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

    # In development the key carries the file's mtime, so a content edit is
    # picked up without a restart; elsewhere the answer never changes, so the
    # key is the path alone and no request pays for a stat. A file that is not
    # there has no mtime, so it keys on its path until it appears.
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

    # A theme may put content_root (or a shared section list) on a base class
    # of its own and have each page inherit it.
    def inherited_setting(name)
      superclass.respond_to?(name) ? superclass.public_send(name) : nil
    end
  end

  def view_template
    content_for(:title) { page_title }
    content_for(:description) { page_description } if page_description

    div(class: "container-public py-8 page page--#{page_slug}", data: { page_slug: page_slug }) do
      h1(class: 'h1') { page_title }

      div(class: 'markdown-content max-w-(--width-prose-lg) text-base leading-relaxed') do
        page_body
      end
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

  # The declared sections, in order. Override for a page that needs more than
  # headings and markdown blocks.
  def page_body
    self.class.sections.each do |section|
      send(section[:heading_level]) { t(section[:heading]) } if section[:heading]
      markdown(section[:path])
    end
  end

  # `raw` writes straight to the buffer, so it composes with anything a page
  # emits around each markdown file.
  def markdown(relative_path)
    root = self.class.content_root || raise(NotImplementedError, "#{self.class} declares no content_root")
    raw safe(Views::ThemeContentPage.markdown_html(root, relative_path))
  end
end
