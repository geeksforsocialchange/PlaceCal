# frozen_string_literal: true

# Configure Phlex components under app/views/ with Views:: namespace.
#
# We define the Views module and push app/views/ as a Zeitwerk root
# so that app/views/base.rb => Views::Base,
# app/views/admin/components/alert.rb => Views::Admin::Components::Alert, etc.

# Define the Views module so Zeitwerk can use it as a namespace root
module Views; end

# Push app/views as a root for the Views namespace
Rails.autoloaders.main.push_dir(
  Rails.root.join('app/views'),
  namespace: Views
)
