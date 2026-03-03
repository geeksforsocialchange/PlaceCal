# frozen_string_literal: true

class Views::Admin::Neighbourhoods::New < Views::Admin::Base
  prop :neighbourhood, Neighbourhood, reader: :private

  def view_template
    p(class: 'alert alert-danger', role: 'alert') do
      plain 'Warning: neighbourhoods should not be created here and this page is only left as a placeholder!'
    end
    PageHeader(model_name: 'Neighbourhood', new_record: true)
    render Views::Admin::Neighbourhoods::Form.new(neighbourhood: neighbourhood)
  end
end
