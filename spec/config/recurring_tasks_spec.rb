# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recurring tasks (config/recurring.yml)" do
  %w[production staging].each do |environment|
    it "schedules the calendar scan hourly and maintenance daily on #{environment}" do
      config = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml"))[environment]
      tasks = config.map { |key, options| SolidQueue::RecurringTask.from_configuration(key, **options.symbolize_keys) }

      expect(tasks).to all(be_valid)
      expect(tasks.to_h { [it.key, [it.class_name, it.schedule]] }).to include(
        "calendar_scan" => ["RecurringCalendarScanJob", "every hour at minute 5"],
        "daily_maintenance" => ["RecurringMaintenanceJob", "every day at 3am"]
      )
    end
  end
end
