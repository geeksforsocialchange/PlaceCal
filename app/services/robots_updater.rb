# frozen_string_literal: true

# Fetches the latest AI bot list from the ai.robots.txt project and
# regenerates the production robots.txt templates.
#
# Usage:
#   RobotsUpdater.call          # fetch + regenerate
#   rails robots:update         # same, via rake task
class RobotsUpdater
  ROBOTS_JSON_URL = 'https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/main/robots.json'

  # Search-AI bots we allow to crawl PlaceCal so events appear in
  # AI-powered search results (Google AI Overviews, Perplexity, etc.)
  SEARCH_ALLOW_LIST = %w[
    Applebot
    Applebot-Extended
    Bravebot
    ChatGPT-User
    Claude-SearchBot
    Claude-User
    DuckAssistBot
    FacebookBot
    facebookexternalhit
    Google-CloudVertexBot
    Google-Extended
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
      lines << '# Search-AI bots (Perplexity, ChatGPT search, Claude search, Google AI,'
      lines << '# Apple, Brave, DuckDuckGo, Facebook) are allowed by default.'
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
