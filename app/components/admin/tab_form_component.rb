# frozen_string_literal: true

module Admin
  class TabFormComponent < ViewComponent::Base
    include SvgIconsHelper

    # Renders a tabbed form with consistent structure across admin resources.
    #
    # @param tabs [Array<Hash>] Array of tab definitions, each containing:
    #   - label: [String] Tab label with emoji (e.g., "📋 Basic Info")
    #   - hash: [String] URL hash for the tab (e.g., "basic")
    #   - partial: [String] Partial path to render (e.g., "form_tab_basic")
    #   - persisted_only: [Boolean] Only show for persisted records (default: false)
    #   - spacer_before: [Boolean] Add flex spacer before this tab (default: false)
    # @param tab_name [String] Name for the tab radio group (e.g., "partner_tabs")
    # @param storage_key [String] sessionStorage key for tab persistence (e.g., "partnerTabAfterSave")
    # @param settings_hash [String] Hash value for settings tab (optional)
    # @param preview_hash [String] Hash value for preview tab (optional)
    # @param form [SimpleForm::FormBuilder] The form builder instance
    # @param record [ActiveRecord::Base] The record being edited
    # @param before_tabs [String] Optional content to render before tabs (e.g., alerts)
    # rubocop:disable Metrics/ParameterLists
    def initialize(tabs:, tab_name:, storage_key:, form:, record:, settings_hash: nil, preview_hash: nil)
      super()
      @tabs = tabs
      @tab_name = tab_name
      @storage_key = storage_key
      @settings_hash = settings_hash
      @preview_hash = preview_hash
      @form = form
      @record = record
    end
    # rubocop:enable Metrics/ParameterLists

    def visible_tabs
      @tabs.select { |tab| !tab[:persisted_only] || @record.persisted? }
    end

    def first_visible_tab
      visible_tabs.first
    end

    private

    attr_reader :tabs, :tab_name, :storage_key, :settings_hash, :preview_hash, :form, :record
  end
end
