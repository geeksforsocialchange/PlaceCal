# frozen_string_literal: true

# @label Save Bar
class Admin::SaveBarComponentPreview < ViewComponent::Preview
  # @label Simple Mode
  def simple
    render(Admin::SaveBarComponent.new) do |bar|
      bar.with_button do
        '<button type="submit" class="btn btn-primary">Save Changes</button>'.html_safe
      end
    end
  end

  # @label With Track Changes
  def with_track_changes
    render(Admin::SaveBarComponent.new(track_changes: true)) do |bar|
      bar.with_button do
        '<button type="submit" class="btn btn-primary">Save</button>'.html_safe
      end
    end
  end

  # @label Multi-step Mode
  def multi_step
    render(Admin::SaveBarComponent.new(
             multi_step: true,
             tab_name: 'partner_tabs',
             settings_hash: 'settings',
             preview_hash: 'preview',
             storage_key: 'partnerTabAfterSave'
           ))
  end

  # @label Wizard Mode
  def wizard
    render(Admin::SaveBarComponent.new(
             wizard: true,
             wizard_controller: 'user-wizard',
             submit_label: 'Send Invitation',
             submit_icon: :mail
           ))
  end

  # @label Multiple Buttons
  def multiple_buttons
    render(Admin::SaveBarComponent.new) do |bar|
      bar.with_button do
        '<a href="#" class="btn btn-ghost">Cancel</a>'.html_safe
      end
      bar.with_button do
        '<button type="submit" class="btn btn-primary">Save & Continue</button>'.html_safe
      end
    end
  end
end
