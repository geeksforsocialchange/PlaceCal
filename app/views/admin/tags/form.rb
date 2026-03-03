# frozen_string_literal: true

class Views::Admin::Tags::Form < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  prop :tag, Tag, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    if tag.system_tag
      div(role: 'alert', class: 'alert bg-yellow-50 border-yellow-200 text-yellow-800 mb-6') do
        raw icon(:warning, size: '5', css_class: 'text-yellow-500')
        span { 'This tag is used by the PlaceCal backend so you cannot change the Name or Slug values.' }
      end
    end

    form_url = if tag.new_record?
                 helpers.admin_tags_path
               elsif tag.is_a?(Partnership)
                 helpers.admin_partnership_path(tag)
               else
                 helpers.admin_tag_path(tag)
               end

    simple_form_for(tag, as: :tag, url: form_url,
                         html: { class: 'space-y-6', data: { controller: 'form-tabs live-validation', 'form-tabs-storage-key-value': 'tagTabAfterSave' } }) do |form|
      Error(tag)

      if tag.new_record?
        render_new_layout(form)
      else
        render_edit_layout(form)
      end

      render_save_bar(form)
    end
  end

  private

  def render_new_layout(form)
    render_basic_info_card(form)
    render_assigned_users_card if show_assigned_user_field_for?(form)
  end

  def render_edit_layout(form) # rubocop:disable Metrics/MethodLength
    div(class: 'tabs tabs-lift') do
      TabPanel(
        name: 'tag_tabs', label: "\u{1F4CB} Basic Info", hash: 'basic',
        controller_name: 'form-tabs', checked: true
      ) { render Views::Admin::Tags::FormTabBasic.new(form: form) }

      TabPanel(
        name: 'tag_tabs', label: "\u{1F3E2} Partners", hash: 'partners',
        controller_name: 'form-tabs'
      ) { render Views::Admin::Tags::FormTabPartners.new(form: form) }

      div(class: 'tab flex-1 cursor-default')

      TabPanel(
        name: 'tag_tabs', label: "\u{2699}\u{FE0F} Settings", hash: 'settings',
        controller_name: 'form-tabs'
      ) { render Views::Admin::Tags::FormTabSettings.new(form: form) }
    end
  end

  def render_basic_info_card(form) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        SectionHeader(title: t('admin.sections.basic_information'), margin: 4)

        div(class: 'fieldset') do
          label(for: 'tag_name', class: 'fieldset-legend') do
            plain attr_label(:tag, :name)
            whitespace
            span(class: 'text-error') { t('admin.labels.required') }
          end
          raw form.input_field(:name, class: 'input input-bordered w-full', id: 'tag_name')
        end

        div(class: 'fieldset') do
          label(for: 'tag_slug', class: 'fieldset-legend') { attr_label(:tag, :slug) }
          raw form.input_field(:slug, class: 'input input-bordered w-full', id: 'tag_slug')
          p(class: 'fieldset-label') { t('admin.hints.leave_blank_to_autogenerate') }
        end

        div(class: 'fieldset') do
          label(for: 'tag_description', class: 'fieldset-legend') { attr_label(:tag, :description) }
          raw form.input_field(:description, as: :text, class: 'textarea textarea-bordered w-full min-h-24',
                                             data: { controller: 'auto-expand' }, id: 'tag_description')
        end

        if helpers.current_user.root?
          fieldset(class: 'fieldset') do
            raw form.input(:system_tag, wrapper: :tw_boolean, hint: t('admin.partnerships.fields.system_tag_hint'))
          end
        end

        render_type_field(form)
      end
    end
  end

  def render_type_field(form)
    div(class: 'fieldset') do
      label(for: 'tag_type', class: 'fieldset-legend') { 'Type' }
      raw form.input_field(:type,
                           as: :select,
                           collection: [['None', ''], ['Category', 'Category'], ['Facility', 'Facility'], ['Partnership', 'Partnership']],
                           class: 'select select-bordered w-full',
                           id: 'tag_type')
      p(class: 'fieldset-label text-amber-700') do
        raw icon(:warning, size: '4', css_class: 'inline-block mr-1')
        plain 'Once set, this cannot be changed.'
      end
    end
  end

  def render_assigned_users_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        div(class: 'flex items-start gap-4 mb-4') do
          div(class: 'shrink-0 w-11 h-11 rounded-xl bg-linear-to-br from-purple-100 to-indigo-100 flex items-center justify-center shadow-sm') do
            raw icon(:users, size: '6', css_class: 'text-purple-600')
          end
          div do
            h3(class: 'card-title text-lg') { t('admin.tags.sections.assigned_users') }
            p(class: 'text-sm text-gray-600 mt-0.5') { t('admin.tags.sections.assigned_users_description') }
          end
        end

        StackedListSelector(
          field_name: 'tag[user_ids][]',
          items: tag.users.order(:last_name, :first_name),
          options: options_for_users,
          permitted_ids: nil,
          icon_name: :user,
          icon_color: 'bg-purple-100 text-purple-600',
          empty_text: t('admin.empty.none_assigned', items: User.model_name.human(count: 2).downcase),
          add_placeholder: t('admin.placeholders.add_model', model: User.model_name.human.downcase),
          use_tom_select: true
        )
      end
    end
  end

  def render_save_bar(form)
    if tag.new_record?
      SaveBar() do
        raw form.submit(t('admin.actions.save'), class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange')
      end
    else
      SaveBar(
        multi_step: true,
        tab_name: 'tag_tabs',
        settings_hash: 'settings',
        storage_key: 'tagTabAfterSave'
      )
    end
  end
end
