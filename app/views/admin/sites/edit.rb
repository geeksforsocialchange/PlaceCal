# frozen_string_literal: true

class Views::Admin::Sites::Edit < Views::Admin::Base
  prop :site, Site, reader: :private
  prop :all_neighbourhoods, ActiveRecord::Relation, reader: :private
  prop :primary_neighbourhood_id, _Nilable(Integer), reader: :private

  def view_template
    PageHeader(model_name: 'Site', title: site.name, id: site.id)
    render Views::Admin::Sites::Form.new(site: site, all_neighbourhoods: all_neighbourhoods,
                                         primary_neighbourhood_id: primary_neighbourhood_id)
  end
end
