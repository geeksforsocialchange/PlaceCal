# frozen_string_literal: true

class Views::Admin::Tags::FormTabBasic < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    tag_record = form.object

    div(class: 'mb-6') do
      render Components::Admin::SectionHeader.new(
        title: t('admin.sections.basic_information')
      )
    end

    div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
      div(class: 'space-y-6') do
        render_details_card(tag_record)
      end

      render_assigned_users_card(tag_record) if show_assigned_user_field_for?(form)
    end
  end

  private

  def render_details_card(tag_record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render Components::Admin::FormCard.new(
      icon: :tag,
      title: t('admin.sections.details'),
      fit_height: true
    ) do
      div(class: 'fieldset') do
        label(for: 'tag_name', class: 'fieldset-legend') do
          plain attr_label(:tag, :name)
          whitespace
          span(class: 'text-error') { t('admin.labels.required') }
        end
        raw form.input_field(:name, class: 'input input-bordered w-full', disabled: tag_record.system_tag, id: 'tag_name')
      end

      div(class: 'fieldset') do
        label(for: 'tag_description', class: 'fieldset-legend') { attr_label(:tag, :description) }
        raw form.input_field(:description, as: :text, class: 'textarea textarea-bordered w-full min-h-24',
                                           data: { controller: 'auto-expand' }, id: 'tag_description')
      end
    end
  end

  def render_assigned_users_card(tag_record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render Components::Admin::FormCard.new(
      icon: :users,
      title: t('admin.tags.sections.assigned_users'),
      description: t('admin.tags.sections.assigned_users_description'),
      fit_height: true
    ) do
      render Components::Admin::StackedListSelector.new(
        field_name: 'tag[user_ids][]',
        items: tag_record.users.order(:last_name, :first_name),
        options: options_for_users,
        permitted_ids: nil,
        icon_name: :user,
        icon_color: 'bg-purple-100 text-purple-600',
        empty_text: t('admin.empty.none_assigned', items: User.model_name.human(count: 2).downcase),
        add_placeholder: t('admin.placeholders.add_model', model: User.model_name.human.downcase),
        use_tom_select: true,
        link_path: :edit_admin_user_path
      )
    end
  end
end
