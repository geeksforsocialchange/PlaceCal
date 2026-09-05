# frozen_string_literal: true

require "rails_helper"

# The generic markdown content page a theme subclasses (#3368 WP 5.2), proved
# against the fixture engine's own content/ directory. What a page says is the
# theme's business; the pipeline, the cache and the wrapper markup are not.
RSpec.describe "Theme content page", type: :request do
  let(:ward) { create(:riverside_ward) }

  let!(:themed_site) do
    site = create(:site, slug: "themed", theme: "example_theme", url: "https://themed.lvh.me")
    site.neighbourhoods << ward
    site
  end

  it "serves the page the theme registered at its slug" do
    get "http://themed.lvh.me/fixture-content"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<title>Fixture content page | #{themed_site.name}</title>")
    expect(response.body).to include('<meta name="description" content="Fixture content page description">')
  end

  # app/tailwind selects on all three in the theme repos, so they are contract.
  it "wraps the page in the markup a theme's CSS selects on" do
    get "http://themed.lvh.me/fixture-content"

    page = Nokogiri::HTML(response.body).at_css("[data-page-slug]")
    expect(page["class"].split).to include("page", "page--fixture-content")
    expect(page["data-page-slug"]).to eq("fixture-content")
    expect(page.at_css("h1").text).to eq("Fixture content page")
    expect(page.at_css(".markdown-content")).to be_present
  end

  it "renders each declared markdown file, in declaration order, under its heading" do
    get "http://themed.lvh.me/fixture-content"

    content = Nokogiri::HTML(response.body).at_css(".markdown-content")
    expect(content.text).to include("Fixture markdown intro paragraph.")
    expect(content.css("li").map(&:text)).to eq(%w[one two])
    expect(content.at_css("h2").text).to eq("Fixture content detail heading")
    expect(content.at_css("a[href='https://example.org']").text).to eq("with a link")
    expect(content.text.index("intro paragraph")).to be < content.text.index("detail paragraph")
  end

  it "sanitises the rendered markdown" do
    get "http://themed.lvh.me/fixture-content"

    expect(response.body).to include("Fixture markdown intro paragraph")
    expect(response.body).not_to include("<script>alert")
  end

  it "lists the page in the sitemap like any other theme page" do
    get "http://themed.lvh.me/sitemap/pages.xml"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<loc>#{themed_site.directory_url.chomp('/')}/fixture-content</loc>")
  end

  it "does not serve it on a site whose theme did not register it" do
    core_site = create(:site, slug: "plain", theme: "pink", url: "https://plain.lvh.me")
    core_site.neighbourhoods << ward

    get "http://plain.lvh.me/fixture-content"

    expect(response).to have_http_status(:not_found)
  end
end

RSpec.describe Views::ThemeContentPage, type: :component do
  let(:site) { create(:site, slug: "themed", theme: "example_theme", url: "https://themed.lvh.me") }

  describe "the declarations" do
    it "reads back what the page declared" do
      expect(ExampleTheme::Views::Content.slug).to eq("fixture-content")
      expect(ExampleTheme::Views::Content.title).to eq("example_theme.content.title")
      expect(ExampleTheme::Views::Content.content_root).to eq(ExampleTheme::Engine.root.join("content"))
      expect(ExampleTheme::Views::Content.sections.map { |s| s[:path] }).to eq(["intro.md", "nested/detail.md"])
    end

    # A theme with several pages puts content_root on a base class of its own.
    it "inherits them, so a theme's own base class can hold the shared parts" do
      subclass = Class.new(ExampleTheme::Views::Content) { slug "later" }

      expect(subclass.content_root).to eq(ExampleTheme::Engine.root.join("content"))
      expect(subclass.title).to eq("example_theme.content.title")
      expect(subclass.slug).to eq("later")
    end

    it "does not leak a section declared on a subclass back into its parent" do
      Class.new(ExampleTheme::Views::Content) { markdown "only-here.md" }

      expect(ExampleTheme::Views::Content.sections.map { |s| s[:path] }).to eq(["intro.md", "nested/detail.md"])
    end
  end

  describe "the markdown cache" do
    it "renders one file once" do
      root = ExampleTheme::Engine.root.join("content")
      described_class.markdown_cache.clear

      first = described_class.markdown_html(root, "intro.md")
      second = described_class.markdown_html(root, "intro.md")

      expect(first).to be_a(String)
      expect(second).to equal(first)
    end

    # In development the key carries the mtime so an edit is picked up without
    # a restart; elsewhere it is the path alone and no request pays for a stat.
    it "keys on the file's mtime in development and on its path otherwise" do
      root = ExampleTheme::Engine.root.join("content")
      described_class.markdown_cache.clear

      allow(Rails.env).to receive(:local?).and_return(true)
      described_class.markdown_html(root, "intro.md")
      expect(described_class.markdown_cache.keys.first).to eq([root.join("intro.md").to_s, File.mtime(root.join("intro.md"))])

      described_class.markdown_cache.clear
      allow(Rails.env).to receive(:local?).and_return(false)
      described_class.markdown_html(root, "intro.md")
      expect(described_class.markdown_cache.keys.first).to eq(root.join("intro.md").to_s)
    end
  end

  # A content file can go missing between releases. One absent block must not
  # take the whole page down with a 500.
  it "logs a missing content file and renders the rest of the page" do
    page = Class.new(Views::ThemeContentPage) do
      content_root ExampleTheme::Engine.root.join("content")
      slug "gappy"
      title "example_theme.content.title"
      markdown "not-committed.md"
      markdown "intro.md"
    end
    allow(Rails.logger).to receive(:warn)

    render_inline(page.new(site: site))

    expect(Rails.logger).to have_received(:warn).with(/content file missing, skipping block/)
    expect(self.page).to have_css(".page--gappy .markdown-content", text: "Fixture markdown intro paragraph.")
  end

  it "says which declaration a page is missing" do
    page = Class.new(Views::ThemeContentPage) { slug "sparse" }

    expect { render_inline(page.new(site: site)) }
      .to raise_error(NotImplementedError, /declares no title/)
  end
end
