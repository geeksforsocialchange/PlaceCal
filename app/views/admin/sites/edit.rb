# frozen_string_literal: true

class Views::Admin::Sites::Edit < Views::Admin::Base
  prop :site, Site, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Site', title: site.name, id: site.id)
    render Views::Admin::Sites::Form.new(site: site)
  end
end
