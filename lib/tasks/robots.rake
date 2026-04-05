# frozen_string_literal: true

namespace :robots do
  desc 'Update AI bot lists from ai.robots.txt project on GitHub'
  task update: :environment do
    RobotsUpdater.call
  end
end
