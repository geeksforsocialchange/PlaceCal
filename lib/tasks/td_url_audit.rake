# frozen_string_literal: true

namespace :td do
  desc 'Audit TransDimension URLs for compatibility with PlaceCal'
  task 'url_audit', [:urls_file] => :environment do |_t, args|
    urls_file = args[:urls_file] || 'doc/audits/td-url-audit-urls.txt'

    unless File.exist?(urls_file)
      puts "ERROR: URLs file not found: #{urls_file}"
      exit 1
    end

    require 'net/http'
    require 'uri'

    # Read URLs
    paths = File.readlines(urls_file).map(&:strip).reject(&:empty?)

    results = []

    # Set up route recognition for transdimension site
    original_url_options = Rails.application.routes.default_url_options
    Rails.application.routes.default_url_options = { host: 'transdimension.lvh.me' }

    puts "Auditing #{paths.length} URLs..."
    puts ''

    paths.each_with_index do |path, idx|
      print "\r[#{idx + 1}/#{paths.length}] #{path}".ljust(80)

      # Check PlaceCal route
      begin
        route_match = Rails.application.routes.recognize_path(path, method: :get)
        route_result = "#{route_match[:controller]}##{route_match[:action]}"
      rescue ActionController::RoutingError
        route_result = 'NO ROUTE'
      end

      # Check TD status
      uri = URI("https://transdimension.uk#{path}")
      td_status = begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 5
        http.read_timeout = 5
        request = Net::HTTP::Head.new(uri.request_uri)
        response = http.request(request)
        response.code.to_i
      rescue StandardError
        'ERROR'
      end

      # Check PlaceCal status
      uri = URI("https://placecal.org#{path}")
      pc_status = begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 5
        http.read_timeout = 5
        request = Net::HTTP::Head.new(uri.request_uri)
        response = http.request(request)
        response.code.to_i
      rescue StandardError
        'ERROR'
      end

      # Determine verdict
      verdict = if route_result == 'NO ROUTE'
                  'NO ROUTE'
                elsif td_status == 'ERROR' || pc_status == 'ERROR'
                  'CHECK FAILED'
                elsif [200, 301].include?(pc_status)
                  'OK'
                elsif pc_status == 404
                  'MISSING'
                else
                  "UNKNOWN (#{pc_status})"
                end

      results << {
        path: path,
        td_status: td_status,
        route: route_result,
        pc_status: pc_status,
        verdict: verdict
      }

      # Rate limit
      sleep 0.3 if idx < paths.length - 1
    end

    Rails.application.routes.default_url_options = original_url_options

    puts "\n"
    puts ''
    puts 'RESULTS:'
    puts '=' * 120

    # Group by verdict
    by_verdict = results.group_by { |r| r[:verdict] }

    puts ''
    puts 'Summary:'
    puts "  OK: #{by_verdict['OK']&.length || 0}"
    puts "  MISSING: #{by_verdict['MISSING']&.length || 0}"
    puts "  NO ROUTE: #{by_verdict['NO ROUTE']&.length || 0}"
    puts "  CHECK FAILED: #{by_verdict['CHECK FAILED']&.length || 0}"
    puts "  UNKNOWN: #{by_verdict['UNKNOWN']&.length || 0}"

    puts ''
    puts 'Issues found:'
    (by_verdict['MISSING'] || []).each do |r|
      puts "  MISSING: #{r[:path]} (route: #{r[:route]}, TD: #{r[:td_status]}, PC: #{r[:pc_status]})"
    end

    (by_verdict['NO ROUTE'] || []).each do |r|
      puts "  NO ROUTE: #{r[:path]}"
    end

    (by_verdict['CHECK FAILED'] || []).each do |r|
      puts "  CHECK FAILED: #{r[:path]}"
    end

    # Write markdown table
    output_file = "doc/audits/td-url-audit-#{Time.zone.today.to_s}.md"

    File.open(output_file, 'w') do |f|
      f.puts '# TransDimension URL Audit'
      f.puts ''
      f.puts "Date: #{Time.zone.today}"
      f.puts ''
      f.puts '## Summary'
      f.puts ''
      f.puts '| Verdict | Count |'
      f.puts '|---------|-------|'
      f.puts "| OK | #{by_verdict['OK']&.length || 0} |"
      f.puts "| MISSING | #{by_verdict['MISSING']&.length || 0} |"
      f.puts "| NO ROUTE | #{by_verdict['NO ROUTE']&.length || 0} |"
      f.puts '| REDIRECT NEEDED | 0 |'
      f.puts ''
      f.puts '## Details'
      f.puts ''
      f.puts '| Path | TD Status | Route | PC Status | Verdict |'
      f.puts '|------|-----------|-------|-----------|---------|'

      results.each do |r|
        f.puts "| `#{r[:path]}` | #{r[:td_status]} | #{r[:route]} | #{r[:pc_status]} | #{r[:verdict]} |"
      end
    end

    puts ''
    puts "Audit report written to: #{output_file}"
  end
end
