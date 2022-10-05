# frozen_string_literal: true

unless ENV['NO_COVERAGE']
  SimpleCov.start 'rails' do
    add_group 'Components', 'app/components'
    add_group 'Constraints', 'app/constraints'
    add_group 'Datatables', 'app/datatables'
    add_group 'GraphQL', 'app/graphql'
    add_group 'Policies', 'app/policies'
    add_group 'Uploaders', 'app/uploaders'

    enable_coverage :branch

    # Please occasionally set this to the current coverage if higher
    minimum_coverage line: 77, branch: 68
    refuse_coverage_drop :line, :branch
  end
end
