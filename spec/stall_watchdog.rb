# frozen_string_literal: true

# Turns a stuck example into a fast failure that says where every thread is waiting.
module StallWatchdog
  LIMIT = Integer(ENV.fetch("SPEC_STALL_SECONDS", "300"))

  class << self
    attr_accessor :current
  end

  module_function

  def install(config)
    config.around do |example|
      StallWatchdog.current = [example.id, StallWatchdog.now]
      example.run
    ensure
      StallWatchdog.current = nil
    end

    Thread.new do
      loop do
        sleep 5
        id, started = current
        next unless started && now - started > LIMIT

        report(id)
        exit!(1)
      end
    end
  end

  def report(id)
    warn "\nStallWatchdog: #{id} has run for over #{LIMIT}s"
    Thread.list.each { |thread| warn "#{thread.inspect}\n  #{Array(thread.backtrace).join("\n  ")}" }
  end

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
