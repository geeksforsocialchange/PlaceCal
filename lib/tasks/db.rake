# frozen_string_literal: true

# Original source: https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
# Merged with: https://gist.github.com/kofronpi/37130f5ed670465b1fe2d170f754f8c6
#
# Usage:
#
# # dump the development db
# rake db:dump
#
# # dump the db in a specific format
# rake db:dump format=sql
#
# # dump a table (e.g. users table)
# rake db:dump:table table=users
#
# # dump a table in a specific format
# rake db:dump:table table=users format=sql
#
# # list dumps
# rake db:dumps
#
# # dump the production db
# RAILS_ENV=production rake db:dump
#
# # restore db based on a backup file pattern (e.g. timestamp)
# rake db:restore pattern=20170101
#
# # note: config/database.yml is used for database configuration,
# #       but you will be prompted for the database user's password
#
# Original source: https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
# Merged with: https://gist.github.com/kofronpi/37130f5ed670465b1fe2d170f754f8c6
require 'English'
namespace :db do
  desc 'Dumps the database to backups'
  task dump: :environment do
    dump_fmt   = ensure_format(ENV.fetch('format', nil))
    dump_sfx   = suffix_for_format(dump_fmt)
    backup_dir = backup_directory(Rails.env, create: true)
    full_path  = nil
    cmd        = nil

    with_config do |_app, host, db, user|
      full_path = "#{backup_dir}/#{Time.now.strftime('%Y%m%d%H%M%S')}_#{db}.#{dump_sfx}"
      cmd       = "pg_dump -F #{dump_fmt} -v -O -o -U '#{user}' -h '#{host}' -d '#{db}' -f '#{full_path}'"
    end

    puts cmd
    system cmd
    puts ''
    puts "Dumped to file: #{full_path}"
    puts ''
  end

  namespace :dump do
    desc 'Dumps a specific table to backups'
    task table: :environment do
      table_name = ENV.fetch('table', nil)

      if table_name.present?
        dump_fmt   = ensure_format(ENV.fetch('format', nil))
        dump_sfx   = suffix_for_format(dump_fmt)
        backup_dir = backup_directory(Rails.env, create: true)
        full_path  = nil
        cmd        = nil

        with_config do |_app, host, db, user|
          full_path = "#{backup_dir}/#{Time.now.strftime('%Y%m%d%H%M%S')}_#{db}.#{table_name.parameterize.underscore}.#{dump_sfx}"
          cmd       = "pg_dump -F #{dump_fmt} -v -O -o -U '#{user}' -h '#{host}' -d '#{db}' -t '#{table_name}' -f '#{full_path}'"
        end

        puts cmd
        system cmd
        puts ''
        puts "Dumped to file: #{full_path}"
        puts ''
      else
        puts 'Please specify a table name'
      end
    end
  end

  desc 'Show the existing database backups'
  task dumps: :environment do
    backup_dir = backup_directory
    puts backup_dir.to_s
    system "/bin/ls -ltR #{backup_dir}"
  end

  desc 'Restores the database from a backup using PATTERN'
  task restore: :environment do
    pattern = ENV.fetch('pattern', nil)

    if pattern.present?
      file = nil
      cmd  = nil

      with_config do |_app, host, db, user|
        backup_dir = backup_directory
        files      = Dir.glob("#{backup_dir}/**/*#{pattern}*")

        case files.size
        when 0
          puts "No backups found for the pattern '#{pattern}'"
        when 1
          file = files.first
          fmt  = format_for_file file

          case fmt
          when nil
            puts "No recognized dump file suffix: #{file}"
          when 'p'
            cmd = "psql -U '#{user}' -h '#{host}' -d '#{db}' -f '#{file}'"
          else
            cmd = "pg_restore -F #{fmt} -v -c -C -U '#{user}' -h '#{host}' -d '#{db}' -f '#{file}'"
          end
        else
          puts "Too many files match the pattern '#{pattern}':"
          puts " #{files.join("\n ")}"
          puts ''
          puts 'Try a more specific pattern'
          puts ''
        end
      end
      unless cmd.nil?
        Rake::Task['db:drop'].invoke
        Rake::Task['db:create'].invoke
        puts cmd
        system cmd
        puts ''
        puts "Restored from file: #{file}"
        puts ''
      end
    else
      puts 'Please specify a file pattern for the backup to restore (e.g. timestamp)'
    end
  end

  # Capitalisation differences:
  # db_dump_filename is intended to be a direct environment argument to the rake task
  # Whereas db_dump_ssh_url is intended to live in .bashrc / wherever
  DB_DUMP_ENV_KEY = 'db_dump_filename'
  DB_DUMP_SSH_URL = 'DB_DUMP_SSH_URL'
  DB_DUMP_STAGING_SSH_URL = 'DB_DUMP_STAGING_SSH_URL'

  desc 'Synchronize staging with the production database in one fell swoop'
  task sync_prod_staging: :environment do
    prod_ssh_url = ENV.fetch(DB_DUMP_SSH_URL, 'root@placecal.org -p 666')

    ssh_url = ENV.fetch(DB_DUMP_STAGING_SSH_URL, 'root@placecal-staging.org -p 666')

    $stdout.puts 'Backing up staging db (May take a while.) ...'
    puts `ssh #{ssh_url} dokku postgres:export placecal-db > $(date -Im)_placecal-staging.sql`

    $stdout.puts 'Replicating production db to staging db (May take a while.) ...'
    puts `ssh #{prod_ssh_url} dokku postgres:export placecal-db | ssh #{ssh_url} dokku postgres:import placecal-db`

    if $CHILD_STATUS.success?
      $stdout.puts 'Replicated production to staging (you might have to run rails db:migrate in dokku?)'
    else
      warn 'Failed to replicate production to staging!'
    end
  end

  desc 'Download production DB dump'
  task dump_production: :environment do
    filename = ENV.fetch(DB_DUMP_ENV_KEY) { "#{Rails.root}/dump/production_#{Time.now.to_i}.sql" }

    ssh_url = ENV.fetch(DB_DUMP_SSH_URL, 'root@placecal.org -p 666')

    $stdout.puts "Downloading production db to #{filename} (May take a while.) ..."
    puts `ssh #{ssh_url} dokku postgres:export placecal-db2 > #{filename}`
    if $CHILD_STATUS.success?
      $stdout.puts "Downloaded production db to #{filename}"
      ENV[DB_DUMP_ENV_KEY] = filename
    else
      warn 'Failed to download DB dump!'
    end
  end

  desc "Restore db dump file #{DB_DUMP_ENV_KEY}=<filename> to local dev DB"
  task restore_local: :environment do
    filename = ENV.fetch(DB_DUMP_ENV_KEY, nil)
    raise "Could not find #{filename} file!" unless File.exist? filename

    $stdout.puts "Restoring DB dump file #{filename} to local dev DB. (May take a while.) ..."
    puts `dropdb placecal_dev && createdb placecal_dev && pg_restore -d placecal_dev #{filename}`

    if $CHILD_STATUS.success?
      $stdout.puts '... done.'
    else
      warn 'Failed to restore DB dump to local dev DB!'
      warn 'Please manually check to see whether local DB dev still exists.'
      exit
    end
  end

  desc 'a better version of db:restore_local'
  task restore_local_2: :environment do
    # this does the same thing as the previous task but in a less hacky way by
    #    utilising rails tasks and configurations.

    filename = ENV.fetch(DB_DUMP_ENV_KEY, nil)
    raise "Could not find #{filename} file!" unless File.exist? filename

    $stdout.puts "Restoring DB dump file #{filename} to local dev DB. (May take a while.) ..."

    db_config = Rails.configuration.database_configuration[Rails.env]

    begin
      Rake::Task['db:drop'].invoke

    rescue ActiveRecord::ProtectedEnvironmentError
      # https://github.com/rails/rails/issues/34041#issuecomment-426097998
      puts "*** DB drop failed, you may have pending migrations ***\n\n"
      raise
    end

    Rake::Task['db:create'].invoke

    command = "pg_restore -h #{db_config['host']} -p #{db_config['port']} -d #{db_config['database']} -U #{db_config['username']} #{filename}"
    puts "running: #{command}"
    system command

    if $CHILD_STATUS.success?
      $stdout.puts '... done.'
    else
      warn 'Failed to restore DB dump to local dev DB!'
      warn 'Please manually check to see whether local DB dev still exists.'
      exit
    end
  end

  desc "Restore db dump file #{DB_DUMP_ENV_KEY}=<filename> to staging server DB"
  task restore_staging: :environment do
    filename = ENV.fetch(DB_DUMP_ENV_KEY, nil)
    ssh_url = ENV.fetch(DB_DUMP_STAGING_SSH_URL, 'root@placecal-staging.org -p 666')
    raise "Could not find #{filename} file!" unless File.exist? filename

    $stdout.puts "Restoring DB dump file #{filename} to staging server DB. (May take a while.) ..."
    puts `< #{filename} ssh #{ssh_url} dokku postgres:import placecal-staging-db`
    if $CHILD_STATUS.success?
      $stdout.puts '... done.'
    else
      warn 'Failed to restore DB dump to staging server DB!'
      warn 'Please manually check to see whether staging server DB still exists.'
      exit
    end
  end

  desc 'Download production DB dump and optionally use it to restore_on_local=1 and/or restore_on_staging=1'
  task dump_production_and_restore_other: :dump_production do
    $stdout.puts "restore_on_local = #{ENV['restore_on_local']}" if ENV['restore_on_local']
    $stdout.puts "restore_on_staging = #{ENV['restore_on_staging']}" if ENV['restore_on_staging']
    Rake::Task['db:restore_local'].execute if ENV['restore_on_local']
    Rake::Task['db:restore_staging'].execute if ENV['restore_on_staging']
  end

  desc 'SCP uploads from production to local server'
  task get_files: :environment do
    $stdout.puts 'Getting files...'
    `scp -r root@placecal.org:/var/lib/dokku/data/storage/placecal/public/ ./`
    $stdout.puts '... done.'
  end

  desc 'Prints out a list of tables and their counts'
  task info: :environment do
    IGNORE_TABLES = %w[ar_internal_metadata delayed_jobs schema_migrations seed_migration_data_migrations].freeze

    puts 'Database Info:'
    puts "  Rails.env=#{Rails.env}"

    db_config = Rails.configuration.database_configuration[Rails.env]
    puts "  database='#{db_config['database']}'"
    puts "  host='#{db_config['host']}'"
    puts "  user='#{db_config['username']}'"
    puts "  password=[#{'*' * db_config['password'].length}]"
    puts ''

    max_len = 0
    table_info = []

    ActiveRecord::Base.connection.tables.sort.each do |table|
      next if IGNORE_TABLES.include?(table)

      sql = "select count(*) from #{table}"
      result = ActiveRecord::Base.connection.execute(sql)
      count = result.first['count']

      max_len = table.length if table.length > max_len
      table_info << [table, count]
    end

    table_info.each do |name, count|
      count_s = count.positive? ? count : '.'
      puts "  #{name.rjust(max_len)}  #{count_s}"
    end

    puts ''
  end

  desc 'finds addresses that aren\'t related to any event, partner or place and removes them'
  task clean_bad_addresses: :environment do
    Address.transaction do
      all_address_ids = Set.new(Address.pluck(:id))
      puts "found #{all_address_ids.count} addresses"

      partner_address_ids = Set.new(Partner.pluck(:address_id))
      event_address_ids = Set.new(Event.pluck(:address_id))

      orphaned_address_ids = all_address_ids.subtract(partner_address_ids | event_address_ids)
      if orphaned_address_ids.empty?
        puts '  no orphaned addresses found'

      else
        puts "  #{orphaned_address_ids.count} orphaned addresses found"
        Address.where(id: orphaned_address_ids).delete_all
      end
    end
  end

  desc 'scrubs events that have the same UID and dtstart, pass in `true` if you want those events deleted'
  task :find_and_clean_duplicate_events, %i[destroy_arg] => :environment do |_t, args|
    destroy = to_boolean(args[:destroy_arg])
    if destroy
      puts 'WARNING! you have selected DESTROY, this is not reversible'
      sleep 5
    end

    bad_events = Event.group(:uid, :dtstart).count.keep_if { |_, count| count > 1 }
    puts "Found #{bad_events.count} events with duplicate IDs"

    bad_events.each do |fields, _|
      uid, dtstart = fields

      event_cluster = Event.where(uid: uid)

      start_date = event_cluster.each_with_object({}) do |event, out|
        out[event.dtstart] = out[event.dtstart].to_i + 1
      end

      bad_dates = start_date.keep_if { |_date, count| count > 1 }
      next if bad_dates.empty?

      bad_dates.each do |date, _count|
        bad_event_cluster = event_cluster.where(dtstart: date).order(updated_at: :desc).offset(1)

        puts "#{uid} has duplicate count: #{bad_event_cluster.count} for date #{date}"
        puts "  #{bad_event_cluster.all.map(&:id).to_json}"

        bad_event_cluster.destroy_all if destroy
      end
    end
  end

  private

  def ensure_format(format)
    return format if %w[c p t d].include?(format)

    case format
    when 'dump' then 'c'
    when 'sql' then 'p'
    when 'tar' then 't'
    when 'dir' then 'd'
    else 'p'
    end
  end

  def suffix_for_format(suffix)
    case suffix
    when 'c' then 'dump'
    when 'p' then 'sql'
    when 't' then 'tar'
    when 'd' then 'dir'
    end
  end

  def format_for_file(file)
    case file
    when /\.dump$/ then 'c'
    when /\.sql$/  then 'p'
    when /\.dir$/  then 'd'
    when /\.tar$/  then 't'
    end
  end

  def backup_directory(suffix = nil, create: false)
    backup_dir = File.join(*[Rails.root, 'db/backups', suffix].compact)

    if create && !Dir.exist?(backup_dir)
      puts "Creating #{backup_dir} .."
      FileUtils.mkdir_p(backup_dir)
    end

    backup_dir
  end

  def with_config
    yield Rails.application.class.parent_name.underscore,
          ActiveRecord::Base.connection_config[:host],
          ActiveRecord::Base.connection_config[:database],
          ActiveRecord::Base.connection_config[:username]
  end

  def to_boolean(value)
    (@boolean ||= ActiveModel::Type::Boolean.new).cast value
  end
end
