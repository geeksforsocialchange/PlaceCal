# frozen_string_literal: true

# @label Form Card
class Admin::FormCardComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::FormCardComponent.new(
             icon: :info,
             title: 'Basic Information'
           )) do
      '<div class="space-y-4">
        <div class="form-control">
          <label class="label"><span class="label-text">Name</span></label>
          <input type="text" class="input input-bordered w-full">
        </div>
        <div class="form-control">
          <label class="label"><span class="label-text">Email</span></label>
          <input type="email" class="input input-bordered w-full">
        </div>
      </div>'.html_safe
    end
  end

  # @label With Description
  def with_description
    render(Admin::FormCardComponent.new(
             icon: :map,
             title: 'Location',
             description: 'Where is this organisation based? This address will be shown publicly.'
           )) do
      '<div class="space-y-4">
        <div class="form-control">
          <label class="label"><span class="label-text">Street Address</span></label>
          <input type="text" class="input input-bordered w-full">
        </div>
        <div class="form-control">
          <label class="label"><span class="label-text">Postcode</span></label>
          <input type="text" class="input input-bordered w-full max-w-xs">
        </div>
      </div>'.html_safe
    end
  end

  # @label Fit Height
  def fit_height
    render(Admin::FormCardComponent.new(
             icon: :clock,
             title: 'Opening Times',
             description: 'When is this location open to the public?',
             fit_height: true
           )) do
      '<p class="text-sm text-base-content/60">Opening times editor would go here.</p>'.html_safe
    end
  end

  # @label Various Icons
  # @param icon select { choices: [info, map, clock, calendar, partner, user, mail, phone, globe, tag] }
  def with_icon(icon: :info)
    render(Admin::FormCardComponent.new(
             icon: icon.to_sym,
             title: "Card with #{icon.to_s.titleize} Icon"
           )) do
      "<p>This card uses the <code>:#{icon}</code> icon.</p>".html_safe
    end
  end
end
