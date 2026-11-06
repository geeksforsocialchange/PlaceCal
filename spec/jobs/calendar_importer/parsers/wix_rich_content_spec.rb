# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::WixRichContent do
  def text(content, *decorations)
    { "type" => "TEXT", "textData" => { "text" => content, "decorations" => decorations } }
  end

  def paragraph(*nodes)
    { "type" => "PARAGRAPH", "nodes" => nodes }
  end

  def html_for(*nodes)
    described_class.to_html({ "nodes" => nodes })
  end

  it "keeps paragraphs and drops empty ones" do
    expect(html_for(paragraph(text("One")), paragraph, paragraph(text("\n")), paragraph(text("Two"))))
      .to eq("<p>One</p><p>Two</p>")
  end

  it "keeps line breaks, and splits a paragraph on a blank line" do
    expect(html_for(paragraph(text("One"), text("\n"), text("Two"), text("\n"), text("\n"), text("Three"), text("\n"))))
      .to eq("<p>One<br>Two</p><p>Three</p>")
  end

  it "renders bold, italic and links" do
    link = { "type" => "LINK", "linkData" => { "link" => { "url" => "https://example.com/?a=1&b=2" } } }

    expect(html_for(paragraph(text("Bold", { "type" => "BOLD" }), text(" "), text("Em", { "type" => "ITALIC" }), text(" "), text("Link", link, { "type" => "UNDERLINE" }))))
      .to eq(%(<p><strong>Bold</strong> <em>Em</em> <a href="https://example.com/?a=1&amp;b=2">Link</a></p>))
  end

  it "renders lists without wrapping items in paragraphs" do
    list = { "type" => "BULLETED_LIST", "nodes" => [{ "type" => "LIST_ITEM", "nodes" => [paragraph(text("Step-free"))] }] }

    expect(html_for(list)).to eq("<ul><li>Step-free</li></ul>")
  end

  it "renders headings at their level" do
    expect(html_for({ "type" => "HEADING", "headingData" => { "level" => 4 }, "nodes" => [text("Lineup")] })).to eq("<h4>Lineup</h4>")
  end

  it "escapes text and drops media" do
    expect(html_for(paragraph(text("<b>Fish & chips</b>")), { "type" => "IMAGE", "nodes" => [] }))
      .to eq("<p>&lt;b&gt;Fish &amp; chips&lt;/b&gt;</p>")
  end
end
