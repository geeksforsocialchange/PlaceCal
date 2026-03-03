# frozen_string_literal: true

class Components::Admin::SaveBar < Components::Admin::Base
  prop :multi_step, _Boolean, default: false
  prop :track_changes, _Boolean, default: false
  prop :tab_name, _Nilable(String), default: nil
  prop :settings_hash, _Nilable(String), default: nil
  prop :preview_hash, _Nilable(String), default: nil
  prop :storage_key, _Nilable(String), default: nil
  prop :wizard, _Boolean, default: false
  prop :wizard_controller, _Nilable(String), default: nil
  prop :submit_label, _Nilable(String), default: nil
  prop :submit_icon, Symbol, default: :check
  prop :continue_text_target, _Boolean, default: false

  def after_initialize
    @button_blocks = []
  end

  def with_button(&block)
    @button_blocks << block
    self
  end

  def view_template(&block)
    # In simple mode, the content block from ERB is treated as button content
    @button_blocks << block if block && !@wizard && !@multi_step

    div(
      class: 'sticky bottom-0 z-40 bg-base-200 border-t border-base-300 py-4 px-4 sm:px-6 -mx-4 sm:-mx-6 mt-6 shadow-[0_-4px_20px_-4px_rgba(0,0,0,0.15)]',
      data: stimulus_data_attributes
    ) do
      if @wizard
        render_wizard_mode
      elsif @multi_step
        render_multi_step_mode
      else
        render_simple_mode
      end
    end
  end

  private

  def stimulus_data_attributes
    return {} unless @multi_step

    attrs = { controller: 'save-bar' }
    attrs['save-bar-tab-name-value'] = @tab_name if @tab_name
    attrs['save-bar-settings-hash-value'] = @settings_hash if @settings_hash
    attrs['save-bar-preview-hash-value'] = @preview_hash if @preview_hash
    attrs['save-bar-storage-key-value'] = @storage_key if @storage_key
    attrs
  end

  def render_wizard_mode
    div(class: 'flex items-center justify-between gap-4') do
      # Left side - Back button
      div do
        button(
          type: 'button',
          class: 'btn bg-base-300 hover:bg-base-content/20 text-base-content border-base-300 gap-2 hidden',
          data: wizard_target('backButton').merge(wizard_action('click', 'previousStep'))
        ) do
          icon(:chevron_left, size: '5')
          span { t('admin.actions.back') }
        end
      end

      # Right side - Continue/Submit
      div(class: 'flex items-center gap-3') do
        button(
          type: 'button',
          class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange gap-2',
          data: wizard_target('continueButton').merge(wizard_action('click', 'nextStep'))
        ) do
          continue_data = @continue_text_target ? wizard_target('continueButtonText') : {}
          span(data: continue_data) { t('admin.actions.continue') }
          icon(:chevron_right, size: '5')
        end

        button(
          type: 'submit',
          class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange gap-2 hidden',
          data: wizard_target('submitButton')
        ) do
          icon(@submit_icon, size: '5')
          span { @submit_label || t('admin.actions.create') }
        end
      end
    end
  end

  def render_multi_step_mode
    div(class: 'flex items-center justify-between gap-4') do
      # Left side
      div(class: 'flex items-center gap-4') do
        button(
          type: 'submit',
          class: 'btn bg-base-300 hover:bg-base-content/20 text-base-content border-base-300 gap-2 hidden',
          data_save_bar_target: 'prevButton',
          data_action: 'click->save-bar#savePrevious',
          formnovalidate: true
        ) do
          icon(:chevron_left, size: '5')
          span(data_save_bar_target: 'prevText') { t('admin.actions.back') }
        end

        div(class: 'hidden items-center gap-2', data_save_bar_target: 'indicator') do
          span(class: 'save-bar-indicator-dot')
          span(class: 'text-sm text-base-content/70') { t('admin.save_bar.unsaved_changes') }
        end
      end

      # Right side
      div(class: 'flex items-center gap-3') do
        button(
          type: 'submit',
          class: 'btn bg-base-300 hover:bg-base-content/20 text-base-content border-base-300',
          data_save_bar_target: 'saveButton',
          data_action: 'click->save-bar#saveOnly'
        ) { t('admin.actions.save') }

        button(
          type: 'submit',
          class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange gap-2 hidden',
          data_save_bar_target: 'continueButton',
          data_action: 'click->save-bar#saveContinue'
        ) do
          span(data_save_bar_target: 'continueText') { t('admin.actions.continue') }
          icon(:chevron_right, size: '5')
        end
      end
    end
  end

  def render_simple_mode
    div(class: 'flex items-center gap-4') do
      if @track_changes
        div(class: 'hidden items-center gap-2', data_form_dirty_target: 'indicator') do
          span(class: 'save-bar-indicator-dot')
          span(class: 'text-sm text-base-content/70') { t('admin.save_bar.unsaved_changes') }
        end
      end

      div(class: 'flex items-center gap-3 ml-auto') do
        @button_blocks.each(&:call)
      end
    end
  end

  def wizard_target(name)
    return {} unless @wizard && @wizard_controller

    { "#{@wizard_controller}-target" => name }
  end

  def wizard_action(event, method)
    return {} unless @wizard && @wizard_controller

    { action: "#{event}->#{@wizard_controller}##{method}" }
  end
end
