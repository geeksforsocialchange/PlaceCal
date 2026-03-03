# frozen_string_literal: true

class Views::Admin::Partnerships::Edit < Views::Admin::Base
  prop :partnership, Partnership, reader: :private

  def view_template
    tag = partnership

    if tag.system_tag && !helpers.current_user.root?
      content_for(:title) { tag.name }

      div(class: 'flex items-center justify-between mb-6') do
        div do
          h1(class: 'text-2xl font-semibold') { tag.name }
          p(class: 'text-gray-600 mt-1') { 'System partnership' }
        end
        div(class: 'text-sm text-gray-600') { "ID: #{tag.id}" }
      end

      div(role: 'alert', class: 'alert alert-warning') do
        raw icon(:warning, size: '6', css_class: 'shrink-0 stroke-current')
        span do
          plain 'This partnership is a '
          strong { 'system partnership' }
          plain ' meaning that it cannot be edited by non-root admins.'
        end
      end
    else
      PageHeader(model_name: 'Partnership', title: tag.name, id: tag.id)
      render Views::Admin::Tags::Form.new(tag: tag)
    end
  end
end
