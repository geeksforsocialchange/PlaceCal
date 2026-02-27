# frozen_string_literal: true

# Configure Phlex namespaces for Zeitwerk autoloading.
#
# Views (full-page renders from controllers):
#   app/views/base.rb => Views::Base
#   app/views/articles/index.rb => Views::Articles::Index
#
# Components (reusable UI pieces):
#   app/components/base.rb => Components::Base
#   app/components/admin/alert.rb => Components::Admin::Alert

# Define namespace modules so Zeitwerk can use them as roots
module Views; end

module Components
  extend Phlex::Kit
end

# Push app/views as a root for the Views namespace
Rails.autoloaders.main.push_dir(
  Rails.root.join('app/views'),
  namespace: Views
)

# Push app/components as a root for the Components namespace
Rails.autoloaders.main.push_dir(
  Rails.root.join('app/components'),
  namespace: Components
)
