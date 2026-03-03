# frozen_string_literal: true

class Views::Admin::Sites::FormTabNeighbourhoods < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private
  prop :all_neighbourhoods, ActiveRecord::Relation, reader: :private
  prop :primary_neighbourhood_id, _Nilable(Integer), reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    site = form.object

    SectionHeader(
      title: Neighbourhood.model_name.human(count: 2),
      description: t('admin.sites.sections.neighbourhoods_description')
    )

    div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
      div(class: 'space-y-6') do
        render_primary_neighbourhood_card(site)
        render_other_neighbourhoods_card(site)
      end

      render_display_level_card
    end
  end

  private

  def render_primary_neighbourhood_card(_site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    FormCard(
      icon: :neighbourhood,
      title: t('admin.sites.sections.main_neighbourhood'),
      description: t('admin.sites.sections.main_neighbourhood_description')
    ) do
      raw form.simple_fields_for(:sites_neighbourhood) { |sn|
        primary = primary_neighbourhood_id.present? ? all_neighbourhoods.where(id: primary_neighbourhood_id).first : nil

        if primary.present?
          render_existing_primary(sn, primary)
        else
          CascadingNeighbourhoodFields(form: sn, relation_type: 'Primary', show_remove: false)
        end
      }
    end
  end

  def render_existing_primary(sites_neighbourhood, primary) # rubocop:disable Metrics/AbcSize
    NeighbourhoodCard(
      neighbourhood: primary,
      show_header: false,
      show_remove: false
    )
    raw sites_neighbourhood.hidden_field(:relation_type, value: 'Primary')
    raw sites_neighbourhood.hidden_field(:neighbourhood_id, value: primary.id)

    return unless primary.legacy_neighbourhood?

    div(role: 'alert', class: 'alert alert-warning py-2 mt-3') do
      raw icon(:warning, size: '5', css_class: 'shrink-0 stroke-current')
      span(class: 'text-sm') { t('admin.sites.neighbourhoods.legacy_warning') }
    end
  end

  def render_other_neighbourhoods_card(site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    FormCard(
      icon: :map_pin,
      title: t('admin.sites.sections.other_neighbourhoods'),
      description: t('admin.sites.sections.other_neighbourhoods_description')
    ) do
      if helpers.policy(site).permitted_attributes.include?(:sites_neighbourhoods)
        nested_form_for(form, :sites_neighbourhoods,
                        add_text: t('admin.actions.add_model', model: Neighbourhood.model_name.human.downcase),
                        add_class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange',
                        partial: 'sites_neighbourhood_fields') do
          raw form.simple_fields_for(:sites_neighbourhoods) { |neighbourhood|
            raw view_context.render('sites_neighbourhood_fields', f: neighbourhood)
          }
        end
      else
        secondary_neighbourhoods = site.sites_neighbourhoods.where.not(relation_type: 'Primary').map(&:neighbourhood)
        ItemBadgeList(
          items: secondary_neighbourhoods,
          icon_name: :map_pin,
          icon_color: 'bg-sky-100 text-sky-600',
          link_path: :admin_neighbourhood_path,
          empty_text: t('admin.empty.no_items', items: Neighbourhood.model_name.human(count: 2).downcase)
        )
      end
    end
  end

  def render_display_level_card
    FormCard(
      icon: :zoom,
      title: t('admin.sites.sections.display_level'),
      description: t('admin.sites.sections.display_level_description'),
      fit_height: true
    ) do
      RadioCardGroup(
        form: form,
        attribute: :badge_zoom_level,
        values: Site.badge_zoom_level.values
      )
    end
  end
end
