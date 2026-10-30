# frozen_string_literal: true

module Analyzers
  # Each nested list multiplies the rows a query loads, which complexity scoring only adds up
  class MaxListNesting < GraphQL::Analysis::Analyzer
    MAX_NESTING = 2

    def initialize(query)
      super
      @nesting = 0
      @max_nesting = 0
    end

    def on_enter_field(_node, _parent, visitor)
      return unless list_field?(visitor)

      @nesting += 1
      @max_nesting = @nesting if @nesting > @max_nesting
    end

    def on_leave_field(_node, _parent, visitor)
      @nesting -= 1 if list_field?(visitor)
    end

    def result
      return if @max_nesting <= MAX_NESTING

      GraphQL::AnalysisError.new("Query nests lists #{@max_nesting} deep, which exceeds the maximum of #{MAX_NESTING}")
    end

    private

    def list_field?(visitor)
      return false if visitor.skipping? || visitor.visiting_fragment_definition?

      field = visitor.field_definition
      !field.introspection? && field.type.list?
    end
  end
end
