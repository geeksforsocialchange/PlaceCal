# frozen_string_literal: true

class Views::Admin::Collections::New < Views::Admin::Base
  prop :collection, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Collection', new_record: true)
    render Views::Admin::Collections::Form.new(collection: collection)
  end
end
