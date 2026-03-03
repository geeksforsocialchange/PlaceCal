# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup'

require 'strict_ivars'
StrictIvars.init(
  include: ["#{__dir__}/../app/**/*"],
  exclude: ["#{__dir__}/../app/views/**/*.erb"]
)
