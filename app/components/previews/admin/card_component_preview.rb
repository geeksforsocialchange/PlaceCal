# frozen_string_literal: true

# @label Card
class Admin::CardComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::CardComponent.new(title: 'Card Title')) do
      'This is the card content. Cards are used throughout the admin interface to group related content.'
    end
  end

  # @label With Icon
  def with_icon
    render(Admin::CardComponent.new(title: 'Settings', icon: :cog)) do
      'Card with an icon in the header.'
    end
  end

  # @label Success Variant
  def success_variant
    render(Admin::CardComponent.new(title: 'Success', variant: :success)) do
      'This card indicates a successful state or positive information.'
    end
  end

  # @label Error Variant
  def error_variant
    render(Admin::CardComponent.new(title: 'Error', variant: :error)) do
      'This card indicates an error state or requires attention.'
    end
  end

  # @label Warning Variant
  def warning_variant
    render(Admin::CardComponent.new(title: 'Warning', variant: :warning)) do
      'This card indicates a warning or caution.'
    end
  end

  # @label Orange Variant (Branded)
  def orange_variant
    render(Admin::CardComponent.new(title: 'Featured', variant: :orange, decorative_blur: :top_right)) do
      'Orange branded card with decorative blur effect.'
    end
  end

  # @label With Header Link
  def with_header_link
    render(Admin::CardComponent.new(
             title: 'Partners',
             header_link: '/admin/partners',
             header_link_text: 'View all'
           )) do
      'Card with a link in the header.'
    end
  end

  # @label With Body Slot
  def with_body_slot
    render(Admin::CardComponent.new(title: 'Custom Body')) do |card|
      card.with_body do
        "<div class='p-4 bg-base-200 rounded'>Custom body content with its own styling</div>".html_safe
      end
    end
  end
end
