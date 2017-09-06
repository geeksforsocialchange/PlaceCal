namespace :import do
  task :events_from_source, [:calendar_id] => [:environment] do |t, args|
    import_events_from_source(args[:calendar_id])
  end

  task all_events: :environment do
    Calendar.all.each do |calendar|
      import_events_from_source(calendar.id)
    end
  end
end

def import_events_from_source(calendar_id)
  begin
  calendar = Calendar.find(calendar_id)

  puts "Importing events for calendar #{calendar.name} for #{calendar.place.try(:name)}"

  calendar.import_events
  rescue => e
    puts e
    puts e.backtrace
    return
  end
end
