# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  before_perform do
    Appsignal::Transaction.current.set_namespace('background')
  end
end
