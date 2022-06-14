require 'test_helper'

class EventBaseHtmlSanitizeTest < ActiveSupport::TestCase
  EventBase = CalendarImporter::Events::Base

  test 'returns blank string with no input' do
    event = EventBase.new(nil)
    output = event.html_sanitize(nil)

    assert_equal '', output
  end

  test 'returns plain text if input' do
    input = 'This is plain text'

    event = EventBase.new(nil)
    output = event.html_sanitize(input)

    assert_equal input, output
  end

  test 'returns content if HTML is input' do
    input = <<-HTML
      <h1>A title!</h1>
      <p>This is input</p>
      <p>Another Paragraph</p>
      <ul>
        <li>One</li>
        <li>Two</li>
        <li>Three</li>
      </ul>
    HTML

    event = EventBase.new(nil)
    output = event.html_sanitize(input)

    expected_output = <<-MARKDOWN
### A title!

This is input

Another Paragraph

* One
* Two
* Three
    MARKDOWN

    assert_equal expected_output.strip, output
  end

  test 'handles badly formed HTML' do
    input = <<-HTML
      <h1>A title!</h2>
      <p>This is input
      <p>Another Paragraph
      <ul>
      </button>
      <p>Things</p>
    HTML

    event = EventBase.new(nil)
    output = event.html_sanitize(input)

    expected_output = [
      # there is a space on the end of this line
      #   that gets stripped by vim when in
      #   heredoc mode. -ik
      '### A title! ',
      '',
      'This is input',
      '',
      'Another Paragraph',
      '',
      'Things',
    ].join("\n")

    assert_equal expected_output.strip, output
  end

#  test 'cleans out non utf-8 input' do
#    # pulled from https://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-test.txt
#    input = '��This is a �����bad string�����'
#
#    event = EventBase.new(nil)
#    output = event.html_sanitize(input)
#
#    expected_output = 'This is a bad string'
#
#    assert_equal expected_output, output
#  end

end

