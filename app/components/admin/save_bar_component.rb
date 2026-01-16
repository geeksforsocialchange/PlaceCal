# frozen_string_literal: true

module Admin
  class SaveBarComponent < ViewComponent::Base
    include SvgIconsHelper

    renders_many :buttons

    # Multi-step mode provides Previous/Save/Continue buttons with unsaved changes indicator
    # Simple mode renders custom buttons passed via the buttons slot
    #
    # @param multi_step [Boolean] Enable multi-step navigation mode (default: false)
    # @param track_changes [Boolean] Show unsaved indicator in simple mode (default: false)
    # @param tab_name [String] Name of the tab radio input group (e.g., 'partner_tabs')
    # @param settings_hash [String] Hash value for settings tab (multi-step only)
    # @param preview_hash [String] Hash value for preview tab (multi-step only)
    # @param storage_key [String] sessionStorage key for restoring tab after save
    # rubocop:disable Metrics/ParameterLists
    def initialize(multi_step: false, track_changes: false, tab_name: nil, settings_hash: nil, preview_hash: nil,
                   storage_key: nil)
      super()
      @multi_step = multi_step
      @track_changes = track_changes
      @tab_name = tab_name
      @settings_hash = settings_hash
      @preview_hash = preview_hash
      @storage_key = storage_key
    end
    # rubocop:enable Metrics/ParameterLists

    def multi_step?
      @multi_step
    end

    def track_changes?
      @track_changes
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
  end
end
