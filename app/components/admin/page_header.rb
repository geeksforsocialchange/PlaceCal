# frozen_string_literal: true

class Components::Admin::PageHeader < Components::Admin::Base
  prop :model_name, String
  prop :title, _Nilable(String), default: nil
  prop :id, _Nilable(_Union(Integer, String)), default: nil
  prop :new_record, _Boolean, default: false

  def view_template
    page_title = if @new_record
                   t('admin.actions.new_model', model: @model_name)
                 else
                   "#{t('admin.actions.edit_model', model: @model_name)}: #{@title}"
                 end

    content_for :title do
      plain page_title
    end

    div(class: 'flex items-center justify-between mb-6') do
      div do
        h1(class: 'text-2xl font-semibold') do
          if @new_record
            plain t('admin.actions.new_model', model: @model_name)
          else
            plain t('admin.actions.edit_model', model: @model_name)
          end
        end
        p(class: 'text-gray-600 mt-1') { @title } if @title.present? && !@new_record
      end
      div(class: 'text-sm text-gray-600') { "#{t('admin.labels.id')}: #{@id}" } if @id.present?
    end
  end
end
