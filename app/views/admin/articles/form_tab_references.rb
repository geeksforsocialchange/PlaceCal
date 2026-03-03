# frozen_string_literal: true

class Views::Admin::Articles::FormTabReferences < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    article = form.object
    disabled_fields = helpers.policy(article).disabled_fields

    div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-8') do
      render_partners_section(article, disabled_fields)
      render_partnerships_section(article, disabled_fields)
    end
  end

  private

  def render_partners_section(article, disabled_fields) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div do
      div(class: 'flex items-start gap-4 mb-4') do
        div(class: 'shrink-0 w-11 h-11 rounded-xl bg-linear-to-br from-emerald-100 to-teal-100 flex items-center justify-center shadow-sm') do
          raw icon(:partner, size: '6', css_class: 'text-emerald-600')
        end
        div do
          h2(class: 'text-lg font-semibold') { Partner.model_name.human(count: 2) }
          p(class: 'text-sm text-gray-600 mt-0.5') { 'Link this article to one or more partners.' }
        end
      end

      render Components::Admin::StackedListSelector.new(
        field_name: 'article[partner_ids][]',
        items: article.partners,
        options: disabled_fields.include?(:partner_ids) ? [] : options_for_partners,
        icon_name: :partner,
        icon_color: 'bg-emerald-100 text-emerald-600',
        empty_text: t('admin.empty.none_assigned', items: Partner.model_name.human(count: 2).downcase),
        add_placeholder: t('admin.placeholders.add_model', model: Partner.model_name.human.downcase),
        wrapper_class: 'article_partners',
        read_only: disabled_fields.include?(:partner_ids)
      )
    end
  end

  def render_partnerships_section(article, disabled_fields) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div do
      div(class: 'flex items-start gap-4 mb-4') do
        div(class: 'shrink-0 w-11 h-11 rounded-xl bg-linear-to-br from-purple-100 to-indigo-100 flex items-center justify-center shadow-sm') do
          raw icon(:partnership, size: '6', css_class: 'text-purple-600')
        end
        div do
          h2(class: 'text-lg font-semibold') { Partnership.model_name.human(count: 2) }
          p(class: 'text-sm text-gray-600 mt-0.5') { 'Link this article to partnerships for filtering and organization.' }
        end
      end

      render Components::Admin::StackedListSelector.new(
        field_name: 'article[tag_ids][]',
        items: article.tags,
        options: disabled_fields.include?(:tag_ids) ? [] : helpers.options_for_tags,
        icon_name: :partnership,
        icon_color: 'bg-purple-100 text-purple-600',
        empty_text: t('admin.empty.none_assigned', items: Partnership.model_name.human(count: 2).downcase),
        add_placeholder: t('admin.placeholders.add_model', model: Partnership.model_name.human.downcase),
        wrapper_class: 'article_tags',
        read_only: disabled_fields.include?(:tag_ids)
      )
    end
  end
end
