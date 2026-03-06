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
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject><body xmlns="http://www.w3.org/1999/xhtml"><script>alert(1)</script></body></foreignObject></svg>'
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

    it "preserves safe href values" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><a href="https://example.com"><text>link</text></a></svg>'
      result = described_class.sanitize(svg)
      expect(result).to include('href="https://example.com"')
    end

    it "removes set elements" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><set attributeName="onmouseover" to="alert(1)"/><rect width="100" height="100"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).not_to include("<set")
      expect(result).to include("<rect")
    end

    it "handles SVGs with viewBox and other standard attributes" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100"><circle cx="50" cy="50" r="40"/></svg>'
      result = described_class.sanitize(svg)
      expect(result).to include('viewBox="0 0 100 100"')
      expect(result).to include("<circle")
    end
  end
end
