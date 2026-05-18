# frozen_string_literal: true

class DirectoryFooterPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Directory::Footer.new
  end
end
