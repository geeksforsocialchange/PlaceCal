# frozen_string_literal: true

# @display context directory
class DirectoryFooterPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Directory::Footer.new
  end
end
