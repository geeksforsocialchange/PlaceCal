# frozen_string_literal: true

class Views::Admin::Collections::Edit < Views::Admin::Base
  prop :collection, Collection, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Collection', title: collection.name, id: collection.id)
    render Views::Admin::Collections::Form.new(collection: collection)
  end
end
