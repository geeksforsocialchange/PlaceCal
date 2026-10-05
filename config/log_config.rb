# frozen_string_literal: true

# Shared production/staging logging, loaded from their environment files.
# INFO by default (drops per-query SQL noise), request-id tagged, broadcast to
# stdout and — when the push key is set — AppSignal for durable retention.
module LogConfig
  def self.apply(config)
    config.log_level = (ENV['RAILS_LOG_LEVEL'].presence || 'info').to_sym
    config.log_tags = [:request_id]
    config.log_formatter = ::Logger::Formatter.new

    return if ENV['RAILS_LOG_TO_STDOUT'].blank?

    stdout_logger = ActiveSupport::Logger.new($stdout)
    stdout_logger.formatter = config.log_formatter
    logger = ActiveSupport::BroadcastLogger.new(ActiveSupport::TaggedLogging.new(stdout_logger))
    logger.broadcast_to(Appsignal::Logger.new('app')) if ENV['APPSIGNAL_PUSH_API_KEY'].present?
    config.logger = logger
  end
end
