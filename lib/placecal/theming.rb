# frozen_string_literal: true

module PlaceCal
  # The scopes, parts, states and variants themes may target (doc/extensions.md, "Styling hooks").
  module Theming
    class UndeclaredPart < StandardError; end

    # parts, tokens: symbols, parts in render order. descriptions: part => what it is. states, variants: part => allowed names.
    Scope = Data.define(:name, :parts, :descriptions, :states, :variants, :tokens, :owner) do
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

      # Lookbook previews mirror app/components: UI::PillPreview previews Components::UI::Pill.
      def component_for_preview(preview) = "Components::#{preview.preview_class_name.delete_suffix('Preview')}"

      def scope_for_preview(preview) = scope_of(component_for_preview(preview))

      # Plain data for theme specs: { "hero" => { parts: [...], states: {...}, variants: {...}, tokens: [...] } }.
      def contract
        scopes.transform_values(&:to_contract)
      end

      # For the Lookbook panel: per part, the elements, enclosing parts and preview labels it renders with,
      # and each scenario that failed to render.
      def survey(scope, preview, view_context)
        found = Hash.new { |hash, part| hash[part] = { elements: [], parents: [], scenarios: [] } }
        errors = {}
        preview.scenarios.each do |scenario|
          html = begin
            render_scenario(scenario, view_context)
          rescue StandardError => e
            errors[scenario.label] = "#{e.class}: #{e.message}"
            nil
          end
          next if html.nil?

          html.css(%([data-scope="#{scope.css_name}"][data-part])).each do |element|
            parent = element.ancestors.find { it.is_a?(Nokogiri::XML::Element) && it['data-scope'] == scope.css_name && it['data-part'] }
            seen = found[element['data-part']]
            seen[:elements] |= [element.name]
            seen[:parents] |= [parent ? parent['data-part'] : '(outermost)']
            seen[:scenarios] |= [scenario.label]
          end
        end
        { parts: found, errors: }
      end

      private

      # nil for a scenario that renders a template rather than a Phlex component.
      def render_scenario(scenario, view_context)
        args = scenario.render_args
        Nokogiri::HTML5.fragment(args[:component].render_in(view_context, &args[:block]).to_s) if args[:component].is_a?(Phlex::SGML)
      end

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
        # parts: { part => one-line description } in render order, or a plain list.
        def theme_scope(name = nil, parts: [], states: {}, variants: {}, tokens: [])
          return @theme_scope || (superclass.theme_scope if superclass.respond_to?(:theme_scope)) if name.nil?

          descriptions = parts.is_a?(Hash) ? parts.transform_keys(&:to_sym) : {}
          @theme_scope = Scope.new(name: name.to_sym, parts: (parts.is_a?(Hash) ? parts.keys : parts).map(&:to_sym), descriptions:,
                                   states:, variants:, tokens:, owner: self)
          Theming.register(@theme_scope)
        end
      end

      # A part's data-scope and data-part, merged into the caller's attributes.
      def part(name, variant: nil, state: nil, **attributes)
        scope = self.class.theme_scope
        check_part(scope, name, variant, state) if Rails.env.local?
        return attributes if scope.nil?

        data = (attributes[:data] || {}).merge(scope: scope.css_name, part: Theming.css_name(name))
        data[:variant] = Theming.css_name(variant) if variant
        data[:state] = Theming.css_name(state) if state
        attributes.merge(data:)
      end

      private

      def check_part(scope, name, variant, state)
        raise UndeclaredPart, "#{self.class} has no theme_scope" if scope.nil?
        raise UndeclaredPart, "#{scope.name} has no part #{name.inspect}" unless scope.parts.include?(name)
        raise UndeclaredPart, "#{scope.name}.#{name} has no variant #{variant.inspect}" if variant && scope.variants.fetch(name, []).exclude?(variant)
        raise UndeclaredPart, "#{scope.name}.#{name} has no state #{state.inspect}" if state && scope.states.fetch(name, []).exclude?(state)
      end
    end
  end
end
