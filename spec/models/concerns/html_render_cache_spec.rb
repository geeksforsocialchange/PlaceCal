# frozen_string_literal: true

require "rails_helper"

RSpec.describe HtmlRenderCache do
  # Use Partner as a real model that includes HtmlRenderCache
  # with fields: description, summary, accessibility_info, hidden_reason
  let(:partner) { create(:partner) }

  describe "markdown rendering" do
    it "converts markdown to HTML on save" do
      partner.update!(description: "**bold text**")
      expect(partner.description_html).to include("<strong>bold text</strong>")
    end

    it "handles markdown links" do
      partner.update!(description: "[PlaceCal](https://placecal.org)")
      expect(partner.description_html).to include('<a href="https://placecal.org">PlaceCal</a>')
    end

    it "handles markdown lists" do
      partner.update!(description: "- item one\n- item two")
      expect(partner.description_html).to include("<li>item one</li>")
      expect(partner.description_html).to include("<li>item two</li>")
    end

    it "handles empty values" do
      partner.update!(description: "")
      expect(partner.description_html.strip).to eq("")
    end
  end

  describe "HTML sanitization" do
    it "strips script tags" do
      partner.update!(description: '<script>alert("xss")</script>')
      expect(partner.description_html).not_to include("<script")
    end

    it "strips event handler attributes" do
      partner.update!(description: '<img src=x onerror="alert(1)">')
      expect(partner.description_html).not_to include("onerror")
      expect(partner.description_html).not_to include("alert")
    end

    it "strips iframe tags" do
      partner.update!(description: '<iframe src="https://evil.com"></iframe>')
      expect(partner.description_html).not_to include("<iframe")
    end

    it "strips style tags" do
      partner.update!(description: "<style>body { display: none }</style>")
      expect(partner.description_html).not_to include("<style")
    end

    it "strips javascript: URLs from links" do
      partner.update!(description: '<a href="javascript:alert(1)">click</a>')
      expect(partner.description_html).not_to include("javascript:")
    end

    it "preserves safe HTML elements" do
      partner.update!(description: "**bold** and _italic_")
      expect(partner.description_html).to include("<strong>bold</strong>")
      expect(partner.description_html).to include("<em>italic</em>")
    end

    it "preserves safe link markup" do
      partner.update!(description: "[safe link](https://example.com)")
      expect(partner.description_html).to include('<a href="https://example.com">safe link</a>')
    end
  end

  describe "force_html_generation!" do
    it "re-renders all cached fields" do
      # Bypass the concern by writing directly to the column
      partner.update_column(:description_html, "<script>old unsafe</script>") # rubocop:disable Rails/SkipsModelValidations

      partner.force_html_generation!
      partner.save!

      expect(partner.reload.description_html).not_to include("<script")
    end
  end

  describe "multiple fields" do
    it "sanitizes all registered html_render_cache fields" do
      partner.update!(
        description: "<script>xss1</script>safe description",
        summary: "<script>xss2</script>safe summary",
        accessibility_info: "<script>xss3</script>safe info"
      )

      expect(partner.description_html).not_to include("<script")
      expect(partner.description_html).to include("safe description")

      expect(partner.summary_html).not_to include("<script")
      expect(partner.summary_html).to include("safe summary")

      expect(partner.accessibility_info_html).not_to include("<script")
      expect(partner.accessibility_info_html).to include("safe info")
    end
  end
end
