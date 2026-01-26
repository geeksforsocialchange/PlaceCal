# frozen_string_literal: true

module Admin
  class SaveBarComponent < ViewComponent::Base
    include SvgIconsHelper

    renders_many :buttons

    # Three modes of operation:
    #
    # 1. Simple mode (default): Renders custom buttons passed via the buttons slot
    #    Example: render Admin::SaveBarComponent.new { |c| c.with_button { submit_tag "Save" } }
    #
    # 2. Multi-step mode: Server-side tab navigation with Previous/Save/Continue buttons
    #    Example: render Admin::SaveBarComponent.new(multi_step: true, tab_name: 'partner_tabs')
    #
    # 3. Wizard mode: Client-side JavaScript navigation for new resource wizards
    #    Example: render Admin::SaveBarComponent.new(wizard: true, wizard_controller: 'user-wizard',
    #                                                submit_label: 'Invite User', submit_icon: :mail)
    #
    # @param multi_step [Boolean] Enable multi-step navigation mode (default: false)
    # @param track_changes [Boolean] Show unsaved indicator in simple mode (default: false)
    # @param tab_name [String] Name of the tab radio input group (e.g., 'partner_tabs')
    # @param settings_hash [String] Hash value for settings tab (multi-step only)
    # @param preview_hash [String] Hash value for preview tab (multi-step only)
    # @param storage_key [String] sessionStorage key for restoring tab after save
    # @param wizard [Boolean] Enable wizard mode for client-side step navigation (default: false)
    # @param wizard_controller [String] Stimulus controller name for wizard targets/actions
    # @param submit_label [String] Label for the final submit button (wizard mode)
    # @param submit_icon [Symbol] Icon for the final submit button (wizard mode, default: :check)
    # @param continue_text_target [Boolean] Add a target for continue button text (for dynamic updates)
    # rubocop:disable Metrics/ParameterLists
    def initialize(multi_step: false, track_changes: false, tab_name: nil, settings_hash: nil, preview_hash: nil,
                   storage_key: nil, wizard: false, wizard_controller: nil, submit_label: nil, submit_icon: :check,
                   continue_text_target: false)
      super()
      @multi_step = multi_step
      @track_changes = track_changes
      @tab_name = tab_name
      @settings_hash = settings_hash
      @preview_hash = preview_hash
      @storage_key = storage_key
      @wizard = wizard
      @wizard_controller = wizard_controller
      @submit_label = submit_label
      @submit_icon = submit_icon
      @continue_text_target = continue_text_target
    end
    # rubocop:enable Metrics/ParameterLists

    def multi_step?
      @multi_step
    end

    def track_changes?
      @track_changes
    end

    def wizard?
      @wizard
    end

    attr_reader :wizard_controller, :submit_label, :submit_icon

    def continue_text_target?
      @continue_text_target
    end

    def stimulus_data_attributes
      return {} unless multi_step?

      attrs = { controller: 'save-bar' }
      attrs['save-bar-tab-name-value'] = @tab_name if @tab_name
      attrs['save-bar-settings-hash-value'] = @settings_hash if @settings_hash
      attrs['save-bar-preview-hash-value'] = @preview_hash if @preview_hash
      attrs['save-bar-storage-key-value'] = @storage_key if @storage_key
      attrs
    end

    # Generate data attributes for wizard mode targets
    def wizard_target(name)
      return {} unless wizard? && wizard_controller

      { "#{wizard_controller}-target" => name }
    end

    # Generate data attributes for wizard mode actions
    def wizard_action(event, method)
      return {} unless wizard? && wizard_controller

      { action: "#{event}->#{wizard_controller}##{method}" }
    end
  end
end
