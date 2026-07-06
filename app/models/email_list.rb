# frozen_string_literal: true

# Code-side registry of email lists (see doc/adr/0015). Each list's
# opt-in/opt-out polarity is defined here and nowhere else: adding a new
# email type is a registry entry plus i18n copy — no migration.
#
# - :opt_out — no subscription row means subscribed (legitimate-interests
#   service email)
# - :opt_in  — no subscription row means not subscribed (explicit consent)
class EmailList
  Definition = Data.define(:key, :default_policy) do
    # @return [Boolean] effective subscription state when no row exists
    def default_subscribed?
      default_policy == :opt_out
    end

    def name
      I18n.t("email_lists.#{key}.name")
    end

    def description
      I18n.t("email_lists.#{key}.description")
    end
  end

  REGISTRY = [
    Definition.new(key: :partner_digest, default_policy: :opt_out),
    Definition.new(key: :partnership_updates, default_policy: :opt_in)
  ].index_by(&:key).freeze

  # @return [Array<Definition>]
  def self.all
    REGISTRY.values
  end

  # @return [Array<String>]
  def self.keys
    REGISTRY.keys.map(&:to_s)
  end

  # @param key [String, Symbol]
  # @return [Definition, nil]
  def self.find(key)
    REGISTRY[key&.to_sym]
  end

  # @param key [String, Symbol]
  # @return [Definition]
  def self.find!(key)
    find(key) || raise(KeyError, "unknown email list: #{key.inspect}")
  end
end
