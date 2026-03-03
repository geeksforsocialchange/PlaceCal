# frozen_string_literal: true

class Views::Admin::Neighbourhoods::Form < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  prop :neighbourhood, Neighbourhood, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    simple_form_for([:admin, neighbourhood], html: { data: { controller: 'form-dirty' } }) do |form|
      render(Components::Admin::Error.new(neighbourhood))

      div(class: 'grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8') do
        div(class: 'lg:col-span-2 space-y-6') do
          render_name_card(form)
          render_admins_card if helpers.policy(neighbourhood).set_users?
        end

        div(class: 'lg:col-span-1') do
          render_official_data_card
        end
      end

      render Components::Admin::SaveBar.new(track_changes: true) do
        raw form.submit(t('admin.actions.save'), class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange')
      end
    end
  end

  private

  def render_name_card(form)
    render Components::Admin::Card.new(title: t('admin.neighbourhoods.form.name_title'), icon: :edit) do
      p(class: 'text-sm text-gray-600 mb-4') { t('admin.neighbourhoods.form.name_description') }
      div(class: 'space-y-4') do
        fieldset(class: 'fieldset') do
          raw form.label(:name, attr_label(:neighbourhood, :name), class: 'fieldset-legend')
          raw form.input_field(:name, class: 'input input-bordered w-full')
        end
        fieldset(class: 'fieldset') do
          raw form.label(:name_abbr, attr_label(:neighbourhood, :name_abbr), class: 'fieldset-legend')
          raw form.input_field(:name_abbr, class: 'input input-bordered w-full')
          p(class: 'fieldset-label mt-1') { t('admin.neighbourhoods.form.name_abbr_hint') }
        end
      end
    end
  end

  def render_admins_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-6') do
        div(class: 'flex items-start gap-4 mb-4') do
          div(class: 'shrink-0 w-11 h-11 rounded-xl bg-linear-to-br from-emerald-100 to-teal-100 flex items-center justify-center shadow-sm') do
            raw icon(:users, size: '6', css_class: 'text-emerald-600')
          end
          div do
            h3(class: 'card-title text-lg') { t('admin.neighbourhoods.form.admins_title') }
            p(class: 'text-sm text-gray-600 mt-0.5') { t('admin.neighbourhoods.form.admins_description') }
          end
        end

        render Components::Admin::StackedListSelector.new(
          field_name: 'neighbourhood[user_ids][]',
          items: neighbourhood.users.order(:last_name),
          options: options_for_users,
          permitted_ids: nil,
          icon_name: :user,
          icon_color: 'bg-emerald-100 text-emerald-600',
          empty_text: t('admin.neighbourhoods.show.no_admins'),
          add_placeholder: t('admin.placeholders.add_model', model: User.model_name.human.downcase),
          use_tom_select: true,
          wrapper_class: 'neighbourhood_users'
        )
      end
    end
  end

  def render_official_data_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    is_current = !neighbourhood.legacy_neighbourhood?

    render Components::Admin::Card.new(title: t('admin.neighbourhoods.form.official_title'), icon: :globe) do
      p(class: 'text-sm text-gray-600 mb-4') { t('admin.neighbourhoods.form.official_description') }
      div(class: 'space-y-3') do
        render_stat_row(t('admin.neighbourhoods.show.stats.level')) do
          div(class: 'flex items-center gap-2') do
            level_badge(neighbourhood.level, size: :small)
            span(class: 'font-medium') { neighbourhood.unit&.titleize || "\u2014" }
          end
        end

        render_stat_row(attr_label(:neighbourhood, :unit_name)) do
          span(class: 'font-medium truncate ml-2') { neighbourhood.unit_name || "\u2014" }
        end

        render_stat_row(t('admin.neighbourhoods.show.stats.ons_code')) do
          span(class: 'font-mono font-medium') { neighbourhood.unit_code_value || "\u2014" }
        end

        div(class: 'flex items-center justify-between py-2') do
          span(class: 'text-sm text-gray-600') { t('admin.neighbourhoods.show.stats.ons_dataset') }
          div(class: 'flex items-center gap-2') do
            span(class: 'font-medium') { neighbourhood.release_date&.strftime('%b %Y') || "\u2014" }
            if is_current
              span(class: 'badge badge-xs badge-success') { t('admin.neighbourhoods.show.stats.current') }
            else
              span(class: 'badge badge-xs badge-warning') { t('admin.neighbourhoods.show.stats.legacy') }
            end
          end
        end
      end
    end
  end

  def render_stat_row(label)
    div(class: 'flex items-center justify-between py-2 border-b border-base-200') do
      span(class: 'text-sm text-gray-600') { label }
      yield
    end
  end
end
