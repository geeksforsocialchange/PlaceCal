# frozen_string_literal: true

module PlaceCal
  # The scopes, parts, states and variants themes may target (doc/extensions.md, "Styling hooks").
  module Theming
    class UndeclaredPart < StandardError; end

    # parts, tokens: symbols. states, variants: part => allowed names.
    Scope = Data.define(:name, :parts, :states, :variants, :tokens, :owner) do
      def css_name = Theming.css_name(name)

      def to_contract
        {
          parts: parts.map { Theming.css_name(it) },
          states: states.to_h { |part, names| [Theming.css_name(part), names.map { Theming.css_name(it) }] },
          variants: variants.to_h { |part, names| [Theming.css_name(part), names.map { Theming.css_name(it) }] },
          tokens: tokens.map(&:to_s)
        }
      end
    end

    class << self
      def css_name(name) = name.to_s.dasherize

      def register(scope)
        registry[scope.css_name] = scope
      end

      # Every declared scope, keyed by its rendered name.
      def scopes
        eager_load
        registry.sort.to_h
      end

      def scope_of(class_name) = class_name.safe_constantize.try(:theme_scope)

      # Plain data for theme specs: { "hero" => { parts: [...], states: {...}, variants: {...}, tokens: [...] } }.
      def contract
        scopes.transform_values(&:to_contract)
      end

      private

      def registry
        @registry ||= {}
      end

      # Scopes register when their class loads, which in development and test is only on first use.
      def eager_load
        return if Rails.application.config.eager_load

        %w[app/components app/views].each { Rails.autoloaders.main.eager_load_dir(Rails.root.join(it)) }
      end
    end

    # Included by Components::Base and Views::Base.
    module Hooks
      extend ActiveSupport::Concern

      class_methods do
        def theme_scope(name = nil, parts: [], states: {}, variants: {}, tokens: [])
          return @theme_scope || (superclass.theme_scope if superclass.respond_to?(:theme_scope)) if name.nil?

          @theme_scope = Scope.new(name: name.to_sym, parts: parts.map(&:to_sym), states:, variants:, tokens:, owner: self)
          Theming.register(@theme_scope)
        end
      end

      # A part's data-scope and data-part, merged into the caller's attributes.
      def part(name, variant: nil, states: {}, **attributes)
        scope = self.class.theme_scope
        check_part(scope, name, variant, states) if Rails.env.local?
        return attributes if scope.nil?

        data = (attributes[:data] || {}).merge(scope: scope.css_name, part: Theming.css_name(name))
        data[:variant] = Theming.css_name(variant) if variant
        states.each { |state, on| data[Theming.css_name(state)] = true if on }
        attributes.merge(data:)
      end

      private

      def check_part(scope, name, variant, states)
        raise UndeclaredPart, "#{self.class} has no theme_scope" if scope.nil?
        raise UndeclaredPart, "#{scope.name} has no part #{name.inspect}" unless scope.parts.include?(name)
        raise UndeclaredPart, "#{scope.name}.#{name} has no variant #{variant.inspect}" if variant && scope.variants.fetch(name, []).exclude?(variant)

        undeclared = states.keys - scope.states.fetch(name, [])
        raise UndeclaredPart, "#{scope.name}.#{name} has no state #{undeclared.first.inspect}" if undeclared.any?
      end
    end
  end
end
