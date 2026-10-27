# frozen_string_literal: true

# @display context directory
# @display padding false
class Directory::FooterPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Directory::Footer.new
  end
end
