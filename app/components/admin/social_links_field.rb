# frozen_string_literal: true

# A partner's social links as a list of URL rows, each naming the platform recognised from its address.
class Components::Admin::SocialLinksField < Components::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder

  def view_template
    fieldset(class: 'fieldset', data: { controller: 'nested-form social-links',
                                        social_links_rules_value: SocialLink.detection_rules.to_json }) do
      legend(class: 'fieldset-legend') { ::Partner.human_attribute_name(:social_links) }
      p(class: 'text-sm text-gray-600 mb-2') { t('admin.partners.social_links.hint') }
      # Submits the list even when every row is removed, so the save empties it
      input(type: 'hidden', name: field_name, value: '')
      template(data_nested_form_target: 'template') { row('', 'NEW_RECORD') }
      div(class: 'space-y-2', data_nested_form_target: 'container') do
        links.each_with_index { |link, index| row(link, index) }
      end
      div(class: 'mt-2') do
        button(type: 'button', class: Components::Admin::NestedForm::ADD_CLASS, data_action: 'nested-form#add') do
          t('admin.partners.social_links.add')
        end
      end
    end
  end

  private

  def links
    @form.object.social_links.presence || ['']
  end

  def field_name
    "#{@form.object_name}[social_links][]"
  end

  def row(link, index)
    div(class: 'nested-fields flex items-center gap-2') do
      input(type: 'url', name: field_name, value: link, id: "#{@form.object_name}_social_links_#{index}",
            class: 'input input-bordered grow min-w-0 bg-base-100', placeholder: 'https://',
            aria_label: t('admin.partners.social_links.input_label'),
            data: { action: 'input->social-links#detect' })
      span(class: 'w-28 shrink-0 text-sm text-gray-600 truncate', data: { social_links_target: 'platform' }) do
        SocialLink.new(link).name if SocialLink.valid_url?(link)
      end
      button(type: 'button', class: 'btn btn-ghost btn-sm btn-square text-error', data_action: 'nested-form#remove') do
        icon(:trash, size: '4')
        span(class: 'sr-only') { t('admin.actions.remove') }
      end
    end
  end
end
