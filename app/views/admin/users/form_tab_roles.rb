# frozen_string_literal: true

class Views::Admin::Users::FormTabRoles < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    user = form.object

    div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
      div(class: 'space-y-6') do
        render_partnerships_card(user)
        render_neighbourhoods_card(user)
      end

      div(class: 'space-y-6') do
        render_sites_card(user)
        render_partners_card(user)
      end
    end
  end

  private

  def render_partnerships_card(user)
    FormCard(
      icon: :partnership,
      title: Partnership.model_name.human(count: 2),
      description: t('admin.users.fields.partnerships_hint')
    ) do
      StackedListSelector(
        field_name: 'user[tag_ids][]',
        items: user.partnerships.order(:name),
        options: options_for_user_partnerships,
        permitted_ids: nil,
        icon_name: :partnership,
        icon_color: 'bg-amber-100 text-amber-700',
        empty_text: t('admin.empty.none_assigned', items: Partnership.model_name.human(count: 2).downcase),
        add_placeholder: t('admin.placeholders.add_model', model: Partnership.model_name.human.downcase),
        wrapper_class: 'user_tags'
      )
    end
  end

  def render_neighbourhoods_card(user)
    neighbourhoods_hint = helpers.current_user.root? ? t('admin.users.fields.neighbourhoods_hint_root') : t('admin.users.fields.neighbourhoods_hint')

    FormCard(
      icon: :map_pin,
      title: Neighbourhood.model_name.human(count: 2),
      description: neighbourhoods_hint
    ) do
      if helpers.current_user.root?
        nested_form_for(form, :neighbourhoods_users,
                        add_text: t('admin.actions.add_model', model: Neighbourhood.model_name.human.downcase),
                        add_class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange mt-2',
                        partial: 'neighbourhoods_user_fields') do
          raw form.simple_fields_for(:neighbourhoods_users) { |nuf|
            raw view_context.render('neighbourhoods_user_fields', f: nuf)
          }
        end
      else
        ItemBadgeList(
          items: user.neighbourhoods.order(:name),
          icon_name: :map_pin,
          icon_color: 'bg-sky-100 text-sky-600',
          link_path: :admin_neighbourhood_path,
          empty_text: t('admin.empty.none_assigned', items: Neighbourhood.model_name.human(count: 2).downcase)
        )
      end
    end
  end

  def render_sites_card(user)
    FormCard(
      icon: :site,
      title: Site.model_name.human(count: 2),
      description: t('admin.users.fields.sites_hint', default: 'Sites where this user is assigned as admin')
    ) do
      sites = user.sites.order(:name)
      if sites.any?
        div(class: 'space-y-2') do
          sites.each do |site|
            render_site_link(site)
          end
        end
      else
        render_empty_sites
      end
    end
  end

  def render_site_link(site)
    link_to(helpers.edit_admin_site_path(site),
            class: 'group flex items-center gap-3 p-3 bg-base-200/80 rounded-xl border border-base-300/50 hover:border-base-300 transition-all') do
      div(class: 'shrink-0 w-9 h-9 rounded-lg bg-purple-100 text-purple-600 flex items-center justify-center') do
        raw icon(:site, size: '5')
      end
      span(class: 'flex-1 font-medium text-sm text-base-content/90') { site.name }
      raw icon(:chevron_right, size: '4', css_class: 'text-gray-400 group-hover:text-gray-600')
    end
  end

  def render_empty_sites
    div(class: 'text-center py-6') do
      div(class: 'inline-flex items-center justify-center w-12 h-12 rounded-xl bg-base-200 mb-2') do
        raw icon(:site, size: '6', css_class: 'text-gray-400')
      end
      p(class: 'text-sm text-gray-600') { t('admin.empty.none_assigned', items: Site.model_name.human(count: 2).downcase) }
    end
  end

  def render_partners_card(user)
    FormCard(
      icon: :partner,
      title: Partner.model_name.human(count: 2),
      description: t('admin.users.fields.partners_hint')
    ) do
      StackedListSelector(
        field_name: 'user[partner_ids][]',
        items: user.partners.order(:name),
        options: options_for_partners(user),
        permitted_ids: permitted_options_for_partners,
        icon_name: :partner,
        icon_color: 'bg-emerald-100 text-emerald-600',
        empty_text: t('admin.empty.none_assigned', items: Partner.model_name.human(count: 2).downcase),
        add_placeholder: t('admin.placeholders.add_model', model: Partner.model_name.human.downcase),
        use_tom_select: true,
        wrapper_class: 'user_partners'
      )
    end
  end
end
