# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArticlesHelper, type: :helper do
  describe "#article_summary_text" do
    it "handles null value" do
      article = build(:article, body: nil)

      output = helper.article_summary_text(article)
      expect(output).to eq("")
    end

    it "handles short text" do
      article = build(:article, body: "This is a body text")

      output = helper.article_summary_text(article)
      expect(output.length).to eq(19)
    end

    it "trims long text" do
      article = build(:article, body: "a" * 250)

      output = helper.article_summary_text(article)
      expect(output.length).to eq(200)
    end

    it "takes the excerpt length from the locale, so a theme can override it" do
      article = build(:article, body: "a" * 250)

      allow(helper).to receive(:t).with("news.index.excerpt_length").and_return("40")

      expect(helper.article_summary_text(article).length).to eq(40)
    end

    # strip_tags re-encodes entities, so without a decode step "&" arrives at
    # the browser as the literal "&amp;". The excerpt is escaped exactly once.
    it "escapes an ampersand exactly once" do
      article = build(:article, body: "Cats & dogs")

      output = helper.article_summary_text(article)
      expect(output).to eq("Cats &amp; dogs")
      expect(CGI.unescapeHTML(output)).to eq("Cats & dogs")
    end

    it "escapes a quoted phrase exactly once" do
      article = build(:article, body: 'She said "hello" loudly')

      output = helper.article_summary_text(article)
      expect(output).not_to include("&amp;")
      # Kramdown turns straight quotes into typographic ones.
      expect(CGI.unescapeHTML(output)).to eq("She said \u201Chello\u201D loudly")
    end

    it "strips a script tag from the body" do
      article = build(:article, body: "Hello <script>alert('xss')</script> world")

      output = helper.article_summary_text(article)
      expect(output).not_to include("<script>")
      expect(output).not_to include("alert")
      expect(CGI.unescapeHTML(output)).to eq("Hello world")
    end
  end
end
