# frozen_string_literal: true

# Rails' mail job doesn't inherit ApplicationJob, so it gets delayed_job's four attempts here
class MailDeliveryJob < ActionMailer::MailDeliveryJob
  retry_on StandardError, attempts: 4, wait: :polynomially_longer
end
