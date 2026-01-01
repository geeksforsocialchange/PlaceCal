# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::Base do
  describe "#html_sanitize" do
    subject(:event) { described_class.new(nil) }

    it "returns blank string with no input" do
      output = event.html_sanitize(nil)

      expect(output).to eq("")
    end

    it "returns plain text if input" do
      input = "This is plain text"
      output = event.html_sanitize(input)

      expect(output).to eq(input)
    end

    it "returns content if HTML is input" do
      input = <<-HTML
        <h1 id="title">A title!</h1>
        <p>This is input</p>
        <p class="content">
          Another Paragraph. <a href="http://example.com/thing">A link</a>
        </p>

        <ul>
          <li>One</li>
          <li>Two</li>
          <li>Three</li>
        </ul>
      HTML

      output = event.html_sanitize(input)

      expected_output = <<~MARKDOWN
        ### A title!

        This is input

        Another Paragraph. [A link][1]

        * One
        * Two
        * Three



        [1]: http://example.com/thing
      MARKDOWN

      expect(output).to eq(expected_output.strip)
    end

    it "handles badly formed HTML" do
      input = <<-HTML
        <h1>A title!</h2>
        <p>This is input
        <p>Another Paragraph
        <ul>
        </button>
        <p>Things</p>
      HTML

      output = event.html_sanitize(input)

      # there is a space on the end of this line
      #   that gets stripped by vim when in
      #   heredoc mode. -ik
      expected_output = [
        "### A title! ",
        "",
        "This is input",
        "",
        "Another Paragraph",
        "",
        "Things"
      ].join("\n")

      expect(output).to eq(expected_output.strip)
    end

    it "given markdown input nothing is changed on output" do
      input = <<~MARKDOWN.strip
        ### A title!

        This is input

        Another Paragraph

        * One
        * Two
        * Three
      MARKDOWN

      output = event.html_sanitize(input)

      expect(output).to eq(input)
    end

    it "can filter out &amp; type HTML entities" do
      bad_text = "<p>VFD PRESENTS: Queer Comedy Nights // Britney &amp; Sarah Kendall</p>"
      output = event.html_sanitize(bad_text, as_plaintext: true)

      clean_text = "VFD PRESENTS: Queer Comedy Nights // Britney & Sarah Kendall"
      expect(output).to eq(clean_text)
    end
  end
end
