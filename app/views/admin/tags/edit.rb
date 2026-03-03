# frozen_string_literal: true

class Views::Admin::Tags::Edit < Views::Admin::Base
  prop :tag, Tag, reader: :private
  prop :current_user, User, reader: :private

  def view_template
    tag_type_name = tag.instance_of?(Tag) ? 'Tag' : "#{tag.class.name} Tag"

    if tag.system_tag && !current_user.root?
      content_for(:title) { tag.name }

      div(class: 'flex items-center justify-between mb-6') do
        div do
          h1(class: 'text-2xl font-semibold') { tag.name }
          p(class: 'text-gray-600 mt-1') { 'System tag' }
        end
        div(class: 'text-sm text-gray-600') { "ID: #{tag.id}" }
      end

      div(role: 'alert', class: 'alert alert-warning') do
        raw icon(:warning, size: '6', css_class: 'shrink-0 stroke-current')
        span do
          plain 'This tag is a '
          strong { 'system tag' }
          plain ' meaning that it cannot be edited by non-root admins.'
        end
      end
    else
      PageHeader(model_name: tag_type_name, title: tag.name, id: tag.id)
      render Views::Admin::Tags::Form.new(tag: tag)
    end
  end
end
