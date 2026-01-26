# frozen_string_literal: true

# @label Section Header
class Admin::SectionHeaderComponentPreview < ViewComponent::Preview
  # @label Default (H2)
  def default
    render(Admin::SectionHeaderComponent.new(
             title: 'Basic Information'
           ))
  end

  # @label With Description
  def with_description
    render(Admin::SectionHeaderComponent.new(
             title: 'Contact Details',
             description: 'How can people get in touch with this organisation?'
           ))
  end

  # @label As H3
  def as_h3
    render(Admin::SectionHeaderComponent.new(
             title: 'Opening Times',
             tag: :h3
           ))
  end

  # @label With Icon
  def with_icon
    render(Admin::SectionHeaderComponent.new(
             title: 'Location Settings'
           )) do |header|
      header.with_icon do
        <<~SVG.html_safe
          <svg class="w-5 h-5 text-placecal-orange" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
        SVG
      end
    end
  end

  # @label Custom Margin
  def custom_margin
    render(Admin::SectionHeaderComponent.new(
             title: 'Tags & Associations',
             description: 'Categorise this partner and link them to partnerships.',
             margin: 8
           ))
  end
end
