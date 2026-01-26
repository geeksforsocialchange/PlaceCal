# frozen_string_literal: true

# @label Fieldset
class Admin::FieldsetComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::FieldsetComponent.new(label: 'Partner Name')) do |fieldset|
      fieldset.with_input do
        '<input type="text" class="input input-bordered w-full" placeholder="Enter partner name">'.html_safe
      end
    end
  end

  # @label With Hint
  def with_hint
    render(Admin::FieldsetComponent.new(
             label: 'Email Address',
             hint: "We'll use this for important notifications."
           )) do |fieldset|
      fieldset.with_input do
        '<input type="email" class="input input-bordered w-full" placeholder="email@example.com">'.html_safe
      end
    end
  end

  # @label Required Field
  def required
    render(Admin::FieldsetComponent.new(
             label: 'Organisation Name',
             required: true
           )) do |fieldset|
      fieldset.with_input do
        '<input type="text" class="input input-bordered w-full" required>'.html_safe
      end
    end
  end

  # @label With Character Counter
  def with_char_counter
    render(Admin::FieldsetComponent.new(
             label: 'Summary',
             hint: 'A brief description of the partner.',
             char_counter: 200
           )) do |fieldset|
      fieldset.with_input do
        '<textarea class="textarea textarea-bordered w-full" maxlength="200" rows="3"></textarea>'.html_safe
      end
    end
  end

  # @label Full Example
  def full_example
    render(Admin::FieldsetComponent.new(
             label: 'Description',
             hint: 'Provide a detailed description of this organisation and its services.',
             required: true,
             char_counter: 500
           )) do |fieldset|
      fieldset.with_input do
        '<textarea class="textarea textarea-bordered w-full" maxlength="500" rows="5" required></textarea>'.html_safe
      end
    end
  end
end
