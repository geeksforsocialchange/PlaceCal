# frozen_string_literal: true

class Views::Admin::Tags::New < Views::Admin::Base
  prop :tag, Tag, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Tag', new_record: true)
    render Views::Admin::Tags::Form.new(tag: tag)
  end
end
