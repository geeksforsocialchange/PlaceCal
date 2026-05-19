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

module Views; end

module Components
  extend Phlex::Kit
end

Rails.autoloaders.main.push_dir(
  Rails.root.join('app/views'),
  namespace: Views
)

Rails.autoloaders.main.push_dir(
  Rails.root.join('app/components'),
  namespace: Components
)
