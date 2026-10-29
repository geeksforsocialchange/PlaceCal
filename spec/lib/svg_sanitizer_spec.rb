# frozen_string_literal: true

require "rails_helper"
require "svg_sanitizer"

RSpec.describe SvgSanitizer do
  def svg(body)
    %(<svg xmlns="http://www.w3.org/2000/svg">#{body}</svg>)
  end

  def sanitized(content)
    Nokogiri::XML(described_class.sanitize(content)).tap(&:remove_namespaces!)
  end

  it "keeps a typical exported logo intact" do
    logo = <<~SVG
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 60">
        <defs>
          <style><![CDATA[.cls-1{fill:url(#grad);}]]></style>
          <linearGradient id="grad"><stop offset="0" stop-color="#e5007e"/></linearGradient>
        </defs>
        <title>Example logo</title>
        <path class="cls-1" d="M10 10h40v40H10z"/><text x="60" y="40">Café</text>
      </svg>
    SVG
    doc = sanitized(logo)

    expect(doc.root["viewBox"]).to eq("0 0 200 60")
    expect(doc.at("style").text).to eq(".cls-1{fill:url(#grad);}")
    expect(doc.at("stop")["stop-color"]).to eq("#e5007e")
    expect(doc.at("path")["class"]).to eq("cls-1")
    expect(doc.at("text").text).to eq("Café")
  end

  it "keeps SVG properties in style attributes and embedded raster images" do
    doc = sanitized(svg('<rect width="1" height="1" style="fill:url(#g);opacity:0.5"/>' \
                        '<image width="1" height="1" href="data:image/png;base64,iVBORw0KGgo="/>'))

    expect(doc.at("rect")["style"]).to eq("fill:url(#g);opacity:0.5")
    expect(doc.at("image")["href"]).to eq("data:image/png;base64,iVBORw0KGgo=")
  end

  it "drops styles that load external resources, and foreignObject" do
    result = described_class.sanitize(svg('<style>@import "https://example.com/x.css";</style>' \
                                          '<rect width="1" height="1" style="fill:url(https://example.com/x.svg#a)"/>' \
                                          '<foreignObject><div xmlns="http://www.w3.org/1999/xhtml">hi</div></foreignObject>'))

    expect(result).to include("<rect")
    expect(result).not_to include("example.com", "foreignObject", "hi")
  end

  it "removes scripts, event handlers and javascript: links" do
    result = described_class.sanitize(svg('<?x ><img src="x">?><script>alert(1)</script>' \
                                          '<a href="java&#9;script:alert(2)"><rect width="1" height="1" onclick="alert(3)"/></a>'))

    expect(result).to include("<rect")
    expect(result).not_to include("alert", "<img", "onclick")
  end

  it "adds the SVG namespace when the file has none, so it renders as an image" do
    doc = Nokogiri::XML(described_class.sanitize('<svg viewBox="0 0 1 1"><rect width="1" height="1"/></svg>'))

    expect(doc.root.namespace.href).to eq("http://www.w3.org/2000/svg")
  end

  it "returns nil for content that isn't a usable SVG" do
    not_svg = "<html><body>hi</body></html>"
    malformed = '<svg xmlns="http://www.w3.org/2000/svg"><rect width="1"'
    nothing_left = svg("<script>alert(1)</script>")

    [not_svg, malformed, nothing_left].each { |content| expect(described_class.sanitize(content)).to be_nil }
  end
end
