# frozen_string_literal: true

require "i18n/tasks"

# Guards against broken `t('...')` calls: every translation key referenced in
# the codebase must exist in config/locales. Configuration (which files to read,
# which dynamic keys to ignore) lives in config/i18n-tasks.yml.
#
# Unused keys are intentionally NOT asserted here. Several namespaces (notably
# admin.*) are looked up through interpolated keys that static analysis cannot
# follow, so a strict gate would produce false positives. Review them manually
# with `bundle exec i18n-tasks unused`.
RSpec.describe "I18n translations" do
  let(:i18n) { I18n::Tasks::BaseTask.new }
  let(:missing_keys) { i18n.missing_keys }

  it "does not have missing keys" do
    expect(missing_keys).to be_empty,
                            "#{missing_keys.leaves.count} i18n keys are missing.\n" \
                            "Run `bundle exec i18n-tasks missing` to list them, or " \
                            "`bundle exec i18n-tasks add-missing` to stub them out.\n\n" \
                            "#{missing_keys}"
  end
end
