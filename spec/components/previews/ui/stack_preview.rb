# frozen_string_literal: true

class UI::StackPreview < Lookbook::Preview
  # @label Sections
  # @notes Children sit one under another, spaced by `gap:` (`:none`, `:xs`, `:sm`, `:sm_md`, `:md`, `:lg` or `:xl`); their own vertical margins are ignored.
  def sections
    render(Example.new do |e|
      e.render(Components::UI::Stack.new(gap: :lg)) do
        { "Opening times" => "Monday to Friday, 9am to 5pm", "Accessibility" => "Step-free access through the side door." }.each do |heading, body|
          e.render(Components::UI::Stack.new(gap: :sm)) do
            e.render(Components::UI::RuledHeading.new(caps: true, rule: :full)) { heading }
            e.p { body }
          end
        end
      end
    end)
  end

  class Example < Phlex::HTML
    def view_template(&) = yield(self)
  end
end
