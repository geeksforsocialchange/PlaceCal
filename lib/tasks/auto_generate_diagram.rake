# frozen_string_literal: true

# Only run in development — not appropriate for production.
RailsERD.load_tasks if Rails.env.development?
