# frozen_string_literal: true

class Views::Admin::Partnerships::New < Views::Admin::Base
  prop :partnership, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Partnership', new_record: true)
    render Views::Admin::Tags::Form.new(tag: partnership)
  end
end
