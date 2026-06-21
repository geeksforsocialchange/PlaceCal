# frozen_string_literal: true

# TestProf — test suite profiling and factory optimisation.
# https://test-prof.evilmartians.io
#
# Profilers (FactoryProf, StackProf, etc.) are activated on demand via env vars
# and need no setup here, e.g.:
#
#   FPROF=1 bin/rspec spec/models   # which factories run, and how often
#   EVENT_PROF=sql.active_record bin/rspec
#
# This file enables FactoryDefault, which lets a test reuse one record across a
# whole example instead of recreating association cascades. It is opt-in and
# changes nothing until a spec calls `create_default(...)` and later `create(...)`
# resolves to that default:
#
#   let(:site) { create_default(:site) }   # reused by everything below
#
require "test_prof/recipes/rspec/factory_default"

TestProf::FactoryDefault.configure do |config|
  config.preserve_traits = true     # only reuse a default when traits match
  config.preserve_attributes = true # ...and when explicit attributes match
end
