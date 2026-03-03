# frozen_string_literal: true

class Views::Admin::Partners::Edit < Views::Admin::Base
  prop :partner, _Any, reader: :private

  def view_template
    content_for(:title) { "Edit Partner: #{partner.name}" }

    render(Components::Admin::Error.new(partner))

    div(class: 'flex items-center justify-between mb-6') do
      div do
        h1(class: 'text-2xl font-semibold') { 'Edit Partner' }
        p(class: 'text-gray-600 mt-1') { partner.name }
      end
      div(class: 'text-sm text-gray-600') { "ID: #{partner.id}" }
    end

    render Views::Admin::Partners::Form.new(partner: partner)
  end
end
