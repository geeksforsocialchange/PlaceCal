# frozen_string_literal: true

class Components::UI::Field < Components::Base
  prop :label, String
  # The id of the control the label is for.
  prop :id, String
  prop :hint, _Nilable(String), default: nil
  prop :attributes, Hash, :**

  def view_template
    div(**@attributes) do
      label(id: label_id, for: @id, class: 'block allcaps-label text-tertiary mb-1') { @label }
      p(id: hint_id, class: 'text-sm text-tertiary mt-0 mb-1') { @hint } if @hint
      yield(self)
    end
  end

  def label_id = "#{@id}_label"

  # Pass to the control as aria-describedby; nil without a hint.
  def hint_id = ("#{@id}_hint" if @hint)
end
