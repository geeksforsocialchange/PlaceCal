# frozen_string_literal: true

require "rails_helper"
require "svg_sanitizer"

RSpec.describe SvgSanitizer do
  describe ".sanitize" do
    it "preserves valid SVG content" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><rect width="100" height="100" fill="red"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).to include("<rect")
      expect(result).to include('fill="red"')
    end

    it "removes script tags" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><script>alert("xss")</script><rect width="100" height="100"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("<script")
      expect(result).not_to include("alert")
      expect(result).to include("<rect")
    end

    it "removes foreignObject elements" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject><body xmlns="http://www.w3.org/1999/xhtml"><script>alert(1)</script></body></foreignObject><rect width="1" height="1"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("foreignObject")
      expect(result).not_to include("alert")
    end

    it "removes event handler attributes" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><rect width="100" height="100" onclick="alert(1)" onload="alert(2)" onerror="alert(3)"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("onclick")
      expect(result).not_to include("onload")
      expect(result).not_to include("onerror")
      expect(result).to include("<rect")
    end

    it "removes javascript: hrefs" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><a href="javascript:alert(1)"><text>click me</text></a></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("javascript:")
      expect(result).to include("<text")
    end

    it "keeps fragment hrefs on use elements and drops external ones" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">' \
            '<defs><path id="p" d="M0 0h1"/></defs><use xlink:href="#p"/>' \
            '<use href="https://example.com/sprite.svg#p"/></svg>'
      doc = Nokogiri::XML(described_class.sanitize(svg))
      doc.remove_namespaces!
      expect(doc.css("use").map { |use| use["href"] }).to eq(["#p", nil])
    end

    it "strips the value from set elements" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><set attributeName="onmouseover" to="alert(1)"/><rect width="100" height="100"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("alert")
      expect(result).to include("<rect")
    end

    it "handles SVGs with viewBox and other standard attributes" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100"><circle cx="50" cy="50" r="40"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).to include('viewBox="0 0 100 100"')
      expect(result).to include("<circle")
    end

    it "drops processing instructions so their contents cannot become HTML when inlined" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><?x ><img id="probe" src="x">?><rect width="1" height="1"/></svg>'
      result = described_class.sanitize(svg)
      expect(Nokogiri::HTML5.fragment(result).css("#probe")).to be_empty
      expect(result).to include("<rect")
    end

    it "drops script elements in other namespaces" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:h="http://www.w3.org/1999/xhtml">' \
            '<h:script>document.title = 1</h:script><rect width="1" height="1"/></svg>'
      result = described_class.sanitize(svg)
      expect(Nokogiri::XML(result).xpath("//*[local-name()='script']")).to be_empty
      expect(result).not_to include("document.title")
    end

    it "drops javascript: hrefs hidden behind character references" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><a href="java&#9;script:alert(1)"><text>click me</text></a></svg>'
      doc = Nokogiri::XML(described_class.sanitize(svg))
      doc.remove_namespaces!
      expect(doc.at("a")["href"]).to be_nil
      expect(doc.at("text").text).to eq("click me")
    end

    it "drops comments and doctypes, and strips javascript: values from animations" do
      svg = '<!DOCTYPE svg [<!ENTITY e "x">]><svg xmlns="http://www.w3.org/2000/svg"><!-- hidden -->' \
            '<a href="#a"><animate attributeName="href" to="javascript:alert(1)"/></a></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("hidden", "DOCTYPE", "javascript")
    end

    it "drops styles that load external resources" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><style>@import "https://example.com/x.css";</style>' \
            '<rect width="1" height="1" style="fill: url(https://example.com/x.svg#a)"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("example.com")
      expect(result).to include("<rect")
    end

    it "drops foreignObject and its content" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject><div xmlns="http://www.w3.org/1999/xhtml">hi</div>' \
            '</foreignObject><rect width="1" height="1"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("foreignObject", "hi")
    end

    it "keeps SVG properties in style attributes, such as gradient fills and stop colours" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><linearGradient id="g"><stop style="stop-color:#e5007e;stop-opacity:1"/>' \
            '</linearGradient><rect width="1" height="1" style="fill:url(#g);opacity:0.5"/></svg>'
      doc = Nokogiri::XML(described_class.sanitize(svg))
      doc.remove_namespaces!
      expect(doc.at("stop")["style"]).to eq("stop-color:#e5007e;stop-opacity:1")
      expect(doc.at("rect")["style"]).to eq("fill:url(#g);opacity:0.5")
    end

    it "keeps embedded raster images" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><image width="1" height="1" href="data:image/png;base64,iVBORw0KGgo="/></svg>'
      doc = Nokogiri::XML(described_class.sanitize(svg))
      doc.remove_namespaces!
      expect(doc.at("image")["href"]).to eq("data:image/png;base64,iVBORw0KGgo=")
    end

    it "keeps a typical exported logo intact" do
      svg = <<~SVG
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 200 60">
          <defs>
            <style><![CDATA[.cls-1{fill:url(#grad);}.cls-2{fill:#231f20;}]]></style>
            <linearGradient id="grad" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0" stop-color="#e5007e"/><stop offset="1" stop-color="#f39200"/>
            </linearGradient>
          </defs>
          <title>Example logo</title>
          <g id="Layer_1"><path class="cls-1" d="M10 10h40v40H10z"/><text class="cls-2" x="60" y="40" font-family="Arial">Café</text></g>
        </svg>
      SVG
      doc = Nokogiri::XML(described_class.sanitize(svg))
      expect(doc.root.namespace.href).to eq("http://www.w3.org/2000/svg")
      expect(doc.root["viewBox"]).to eq("0 0 200 60")
      expect(doc.at_css("style").text).to eq(".cls-1{fill:url(#grad);}.cls-2{fill:#231f20;}")
      expect(doc.css("stop").map { |stop| stop["stop-color"] }).to eq(%w[#e5007e #f39200])
      expect(doc.at_css("path")["class"]).to eq("cls-1")
      expect(doc.at_css("text").text).to eq("Café")
      expect(doc.at_css("title").text).to eq("Example logo")
    end

    it "gives an SVG without an xmlns the SVG namespace so it still renders as an image" do
      result = described_class.sanitize('<svg viewBox="0 0 1 1"><rect width="1" height="1"/></svg>')
      doc = Nokogiri::XML(result)
      expect(doc.root.namespace.href).to eq("http://www.w3.org/2000/svg")
      expect(doc.at_xpath("//svg:rect", "svg" => "http://www.w3.org/2000/svg")).to be_present
    end

    it "returns nil for a file that is not an SVG" do
      expect(described_class.sanitize("<html><body>hi</body></html>")).to be_nil
    end

    it "returns nil for a file that is not well-formed XML" do
      expect(described_class.sanitize('<svg xmlns="http://www.w3.org/2000/svg"><rect width="1"')).to be_nil
    end

    it "returns nil when nothing drawable is left after sanitising" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'
      expect(described_class.sanitize(svg)).to be_nil
    end
  end
end
