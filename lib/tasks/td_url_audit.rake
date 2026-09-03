# frozen_string_literal: true

namespace :td do
  desc 'Audit TransDimension URLs for compatibility with PlaceCal'
  # Checks every legacy TransDimension path three ways: the live TD site, the
  # live PlaceCal deployment, and a local dev server running this branch. The
  # dev column is what tells you whether a routing fix on the branch works,
  # since the fix is not on placecal.org until it deploys.
  #
  # Bases can be overridden:
  #   TD_BASE_URL   default https://transdimension.uk
  #   PC_BASE_URL   default https://placecal.org
  #   DEV_BASE_URL  default http://transdimension.lvh.me:3030 (set to '' to skip)
  task 'url_audit', [:urls_file] => :environment do |_t, args|
    urls_file = args[:urls_file] || 'doc/audits/td-url-audit-urls.txt'

    unless File.exist?(urls_file)
      puts "ERROR: URLs file not found: #{urls_file}"
      exit 1
    end

    require 'net/http'
    require 'uri'

    td_base = ENV.fetch('TD_BASE_URL', 'https://transdimension.uk')
    pc_base = ENV.fetch('PC_BASE_URL', 'https://placecal.org')
    dev_base = ENV.fetch('DEV_BASE_URL', 'http://transdimension.lvh.me:3030')
    dev_base = nil if dev_base.blank?

    request_status = lambda do |base, path|
      uri = URI("#{base}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 5
      http.read_timeout = 5
      http.request(Net::HTTP::Head.new(uri.request_uri)).code.to_i
    rescue StandardError
      'ERROR'
    end

    # A single dropped connection or a dev server reloading mid-run should not
    # be reported as a broken URL, so retry anything that is not a real answer.
    head_status = lambda do |base, path|
      status = request_status.call(base, path)
      return status unless status == 'ERROR' || (status.is_a?(Integer) && status >= 500)

      sleep 1
      request_status.call(base, path)
    end

    # Read URLs
    paths = File.readlines(urls_file).map(&:strip).reject(&:empty?)

    results = []

    # Set up route recognition for transdimension site
    original_url_options = Rails.application.routes.default_url_options
    Rails.application.routes.default_url_options = { host: 'transdimension.lvh.me' }

    puts "Auditing #{paths.length} URLs..."
    puts "  TD:  #{td_base}"
    puts "  PC:  #{pc_base}"
    puts "  DEV: #{dev_base || '(skipped)'}"
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

      td_status = head_status.call(td_base, path)
      pc_status = head_status.call(pc_base, path)
      dev_status = dev_base ? head_status.call(dev_base, path) : nil

      # The dev server runs this branch, so it decides the verdict when it is
      # available. A path that 404s in dev but works in production is missing
      # local seed data, not a missing route.
      subject_status = dev_status || pc_status

      verdict = if route_result == 'NO ROUTE'
                  'NO ROUTE'
                elsif subject_status == 'ERROR'
                  'CHECK FAILED'
                elsif [200, 301, 302, 308].include?(subject_status)
                  'OK'
                elsif subject_status == 404 && dev_status == 404 && [200, 301, 302, 308].include?(pc_status)
                  'NO DEV DATA'
                elsif subject_status == 404
                  'MISSING'
                else
                  "UNKNOWN (#{subject_status})"
                end

      results << {
        path: path,
        td_status: td_status,
        route: route_result,
        pc_status: pc_status,
        dev_status: dev_status,
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
    counts = ->(key) { by_verdict[key]&.length || 0 }

    puts ''
    puts 'Summary:'
    puts "  OK: #{counts.call('OK')}"
    puts "  NO DEV DATA: #{counts.call('NO DEV DATA')}"
    puts "  MISSING: #{counts.call('MISSING')}"
    puts "  NO ROUTE: #{counts.call('NO ROUTE')}"
    puts "  CHECK FAILED: #{counts.call('CHECK FAILED')}"

    puts ''
    puts 'Issues found:'
    (by_verdict['MISSING'] || []).each do |r|
      puts "  MISSING: #{r[:path]} (route: #{r[:route]}, TD: #{r[:td_status]}, PC: #{r[:pc_status]}, DEV: #{r[:dev_status]})"
    end

    (by_verdict['NO ROUTE'] || []).each do |r|
      puts "  NO ROUTE: #{r[:path]}"
    end

    (by_verdict['CHECK FAILED'] || []).each do |r|
      puts "  CHECK FAILED: #{r[:path]}"
    end

    # Write markdown table
    output_file = "doc/audits/td-url-audit-#{Time.zone.today}.md"

    File.open(output_file, 'w') do |f|
      f.puts '# TransDimension URL Audit'
      f.puts ''
      f.puts "Date: #{Time.zone.today}"
      f.puts ''
      f.puts "TD: #{td_base}"
      f.puts ''
      f.puts "PlaceCal (production): #{pc_base}"
      f.puts ''
      f.puts "Dev (this branch): #{dev_base || '(skipped)'}"
      f.puts ''
      f.puts '## Summary'
      f.puts ''
      f.puts '| Verdict | Count |'
      f.puts '|---------|-------|'
      f.puts "| OK | #{counts.call('OK')} |"
      f.puts "| NO DEV DATA | #{counts.call('NO DEV DATA')} |"
      f.puts "| MISSING | #{counts.call('MISSING')} |"
      f.puts "| NO ROUTE | #{counts.call('NO ROUTE')} |"
      f.puts "| CHECK FAILED | #{counts.call('CHECK FAILED')} |"
      f.puts ''
      f.puts '## Details'
      f.puts ''
      f.puts '| Path | TD Status | Route | PC Status | Dev Status | Verdict |'
      f.puts '|------|-----------|-------|-----------|------------|---------|'

      results.each do |r|
        f.puts "| `#{r[:path]}` | #{r[:td_status]} | #{r[:route]} | #{r[:pc_status]} | " \
               "#{r[:dev_status] || 'n/a'} | #{r[:verdict]} |"
      end
    end

    puts ''
    puts "Audit report written to: #{output_file}"
  end
end
