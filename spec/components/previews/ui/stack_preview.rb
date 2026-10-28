# frozen_string_literal: true

class UI::StackPreview < Lookbook::Preview
  # @label Sections
  # @notes Children sit one under another, spaced by `gap:` (`:none`, `:xs`, `:sm`, `:md`, `:lg` or `:xl`); their own vertical margins are ignored.
  def sections
    render Components::UI::Stack.new(gap: :lg) do
      safe_join([
                  render(Components::UI::Stack.new(gap: :sm)) do
                    safe_join([render(Components::UI::RuledHeading.new(caps: true, rule: :full)) { "Opening times" }, tag.p do
                      "Monday to Friday, 9am to 5pm"
                    end])
                  end,
                  render(Components::UI::Stack.new(gap: :sm)) { safe_join([render(Components::UI::RuledHeading.new(caps: true, rule: :full)) { "Accessibility" }, tag.p { "Step-free access through the side door." }]) }
                ])
    end
  end
end
