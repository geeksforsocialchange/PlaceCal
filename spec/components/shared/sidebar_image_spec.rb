# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Shared::SidebarImage, type: :phlex do
  it "offers WebP copies ahead of the image when given" do
    render_inline(described_class.new(src: "/a.jpg", alt: "A cafe", webp_srcset: "/a.webp 1x, /a@2x.webp 2x"))

    expect(page).to have_css("picture source[type='image/webp'][srcset='/a.webp 1x, /a@2x.webp 2x']", visible: :all)
    expect(page).to have_css("picture img[src='/a.jpg'][alt='A cafe']")
  end

  it "shows only the image without WebP copies" do
    render_inline(described_class.new(src: "/a.jpg", alt: "A cafe"))

    expect(page).to have_no_css("source", visible: :all)
  end
end
