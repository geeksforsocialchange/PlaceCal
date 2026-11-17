# frozen_string_literal: true

# What one import run noticed, kept as entries and rendered to the strings stored in Calendar#notices.
class CalendarImporter::ImportReport
  # kind is a Symbol; uid and title name the source event when the entry is about one.
  # Either key and values give the locale string, or messages holds text that is already rendered.
  Entry = Data.define(:kind, :uid, :title, :key, :values, :messages) do
    # @return [String]
    def to_s
      messages ? messages.join(', ') : I18n.t(key, **values)
    end
  end

  # @return [Array<Entry>] in the order they were added
  attr_reader :entries

  def initialize
    @entries = []
  end

  # @param kind [Symbol]
  # @param key [String] the locale key
  # @param values [Hash] the locale key's interpolation values
  # @return [Entry]
  def add(kind, key, values: {}, uid: nil, title: nil)
    record(Entry.new(kind:, uid:, title:, key:, values: values.dup.freeze, messages: nil))
  end

  # @param kind [Symbol]
  # @param messages [Array<String>] rendered text, joined with ", " into one notice
  # @return [Entry]
  def add_messages(kind, messages, uid: nil, title: nil)
    record(Entry.new(kind:, uid:, title:, key: nil, values: {}.freeze, messages: messages.dup.freeze))
  end

  # @return [Array<String>] one notice per entry, in order
  def notices
    entries.map(&:to_s)
  end

  private

  def record(entry)
    entries << entry
    entry
  end
end
