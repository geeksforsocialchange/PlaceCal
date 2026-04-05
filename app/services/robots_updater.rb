# frozen_string_literal: true

# Fetches the latest AI bot list from the ai.robots.txt project and
# regenerates the production robots.txt templates.
#
# Usage:
#   RobotsUpdater.call          # fetch + regenerate
#   rails robots:update         # same, via rake task
class RobotsUpdater
  ROBOTS_JSON_URL = 'https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/main/robots.json'

  # Bots allowed to crawl PlaceCal so events appear in search results.
  #
  # Rubric — allow if the bot's primary purpose is one of:
  #   1. Search: answers a user's query with attribution/links back to source
  #   2. User agent: acts on behalf of a specific user's prompt in real-time
  #   3. Link previews: fetches content for social sharing
  #
  # Block if the bot's primary purpose is:
  #   1. Training: collects data for model training or dataset building
  #   2. Enterprise AI platform: feeds an AI-as-a-service product
  #   3. Unknown/undocumented: default to block
  SEARCH_ALLOW_LIST = %w[
    AddSearchBot
    Amzn-SearchBot
    Applebot
    AzureAI-SearchBot
    Bravebot
    ChatGPT-User
    Claude-SearchBot
    Claude-User
    DuckAssistBot
    facebookexternalhit
    OAI-SearchBot
    Perplexity-User
    PerplexityBot
  ].freeze

  ROBOTS_DIR = Rails.root.join('config/robots')

  def self.call(output: $stdout)
    new(output:).call
  end

  def initialize(output: $stdout)
    @output = output
  end

  def call
    bot_names = fetch_bot_names
    write_strict_template(bot_names)
    write_default_template(bot_names)
    print_summary(bot_names)
  end

  private

  def fetch_bot_names
    response = HTTParty.get(ROBOTS_JSON_URL)
    raise "Failed to fetch robots.json: HTTP #{response.code}" unless response.success?

    JSON.parse(response.body).keys.sort_by(&:downcase)
  end

  def write_strict_template(bot_names)
    content = build_robots_txt(bot_names, allow_search: false)
    ROBOTS_DIR.join('robots.production.strict.txt').write(content)
  end

  def write_default_template(bot_names)
    content = build_robots_txt(bot_names, allow_search: true)
    ROBOTS_DIR.join('robots.production.txt').write(content)
  end

  def build_robots_txt(bot_names, allow_search:)
    blocked = allow_search ? bot_names.reject { |name| SEARCH_ALLOW_LIST.include?(name) } : bot_names

    lines = []
    lines << '# See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file'
    lines << '#'

    if allow_search
      lines << '# AI search bots and user agents are allowed by default.'
      lines << '# Training crawlers and enterprise AI platforms are blocked.'
      lines << '# Set ALLOW_AI_SEARCH_BOTS=false to block all AI bots.'
    else
      lines << '# Strict mode: all AI bots are blocked.'
    end

    lines << ''
    lines << 'User-agent: *'
    lines << 'Disallow: /assets/'
    lines << ''
    lines << '# https://github.com/ai-robots-txt/ai.robots.txt'
    lines << '# Training and scraping bots (search-AI bots removed from block list)' if allow_search

    blocked.each { |name| lines << "User-agent: #{name}" }

    lines << 'Disallow: /'
    lines << ''

    lines.join("\n")
  end

  def print_summary(bot_names)
    blocked_default, allowed = bot_names.partition { |name| SEARCH_ALLOW_LIST.exclude?(name) }

    @output.puts "Updated from #{ROBOTS_JSON_URL}"
    @output.puts "Total bots in upstream list: #{bot_names.size}"
    @output.puts "Search bots allowed (default): #{allowed.size} (#{allowed.join(', ')})"
    @output.puts "Bots blocked (default): #{blocked_default.size}"
    @output.puts "Bots blocked (strict): #{bot_names.size}"
    @output.puts 'Files written:'
    @output.puts '  config/robots/robots.production.txt'
    @output.puts '  config/robots/robots.production.strict.txt'
  end
end
