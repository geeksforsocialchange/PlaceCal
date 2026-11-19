# frozen_string_literal: true

# The event types a listing shows, one checkbox each. Every event is exactly one type (Event.of_types).
class EventTypes
  ALL = %w[one_off repeating long_running].freeze
  # The old three-way params as ticked boxes: off unticks that type, only ticks it alone
  LEGACY = {
    repeating: { 'off' => ALL - %w[repeating], 'only' => %w[repeating] },
    long_running: { 'off' => ALL - %w[long_running], 'only' => %w[long_running] }
  }.freeze

  # The filter forms send a blank types[] beside the boxes, so no box ticked reads as none rather than as the default.
  def self.from_params(params)
    return new(Array(params[:types]).grep(String)) unless params[:types].nil?

    new(LEGACY.filter_map { |name, map| map[params[name]] }.reduce(ALL, :&))
  end

  def self.all = new

  attr_reader :to_a

  def initialize(types = ALL)
    @to_a = ALL & types
  end

  delegate :include?, :exclude?, to: :to_a
  def all? = to_a == ALL
  def hidden = ALL - to_a

  # For links and hidden fields: nothing for the default, and a blank types[] for none
  def field_values = all? ? [] : to_a.presence || ['']
  def to_params = all? ? {} : { types: field_values }

  def ==(other) = other.is_a?(EventTypes) && to_a == other.to_a
end
