# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Solid Queue retries nothing by itself; delayed_job gave every job four attempts. Imports handle their own failures
  retry_on StandardError, attempts: 4, wait: :polynomially_longer

  before_perform do
    Appsignal::Transaction.current.set_namespace('background')
  end
end
