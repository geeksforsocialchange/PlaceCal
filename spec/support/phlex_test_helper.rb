# frozen_string_literal: true

# Test helper for rendering Phlex components in specs.
# Provides render_inline that works like ViewComponent's render_inline
# but for Phlex components (compatible with Phlex 2.x + phlex-rails).
module PhlexTestHelper
  def render_inline(component, &)
    html = component.render_in(view_context, &)
    @page = Capybara::Node::Simple.new(html)
  end

  def page
    @page
  end

  private

  def view_context
    @view_context ||= begin
      controller = ApplicationController.new
      controller.request = ActionDispatch::TestRequest.create
      controller.view_context
    end
  end
end
