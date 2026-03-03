# frozen_string_literal: true

class Views::Admin::Supporters::New < Views::Admin::Base
  prop :supporter, Supporter, reader: :private

  def view_template
    PageHeader(model_name: 'Supporter', new_record: true)
    render Views::Admin::Supporters::Form.new(supporter: supporter)
  end
end
