# frozen_string_literal: true

class Views::Admin::Sites::New < Views::Admin::Base
  prop :site, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Site', new_record: true)
    render Views::Admin::Sites::Form.new(site: site)
  end
end
