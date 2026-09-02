# frozen_string_literal: true

class Views::Admin::Pages::Edit < Views::Admin::Base
  prop :page, Page, reader: :private
  prop :sites, _Interface(:each), reader: :private

  def view_template
    PageHeader(model_name: Page.model_name.human, title: page.title, id: page.id)
    render Views::Admin::Pages::Form.new(page: page, sites: sites)
  end
end
