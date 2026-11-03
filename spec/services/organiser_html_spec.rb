# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganiserHtml do
  def headings(html)
    Nokogiri::HTML5.fragment(html).css("h1, h2, h3, h4, h5, h6").map(&:name)
  end

  it "starts organiser headings one level below the page heading above them" do
    expect(headings(described_class.call("<h1>About</h1><h2>Opening</h2>", under: 1))).to eq(%w[h2 h3])
  end

  it "closes gaps between levels so nothing is skipped" do
    expect(headings(described_class.call("<h2>A</h2><h4>B</h4><h2>C</h2><h6>D</h6>", under: 2))).to eq(%w[h3 h4 h3 h5])
  end

  it "never goes below h6" do
    expect(headings(described_class.call("<h1>A</h1><h2>B</h2><h3>C</h3><h4>D</h4>", under: 4))).to eq(%w[h5 h6 h6 h6])
  end

  it "makes an image with no alt decorative and keeps alt text it was given" do
    html = described_class.call('<p><img src="a.png"><img src="b.png" alt="A map"></p>', under: 1)

    expect(Nokogiri::HTML5.fragment(html).css("img").map { |img| img["alt"] }).to eq(["", "A map"])
  end

  it "leaves text and links as they are" do
    expect(described_class.call('<p>Hello <a href="/x">there</a></p>', under: 1)).to eq('<p>Hello <a href="/x">there</a></p>')
  end

  it "returns blank input unchanged" do
    expect(described_class.call(nil, under: 1)).to eq("")
  end
end
