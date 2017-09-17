namespace :import do
  task :events_from_source, [:calendar_id] => [:environment] do |t, args|
    import_events_from_source(args[:calendar_id], Date.today.beginning_of_day, 1.year.from_now)
  end

  task all_events: :environment do
    Calendar.without_type(:other).each do |calendar|
      import_events_from_source(calendar.id)
    end
  end

  #calendar_id - object id of calendar to be imported.
  #from - import events starting from this date. Must use format 'dd-mm-yy'.
  #to - import events up until this date. Must use format 'dd-mm-yy' and must be greater than from date.

  task :past_events_from_source, [:calendar_id, :from, :to] => [:environment] do |t, args|
    from = DateTime.parse(args[:from])
    to   = DateTime.parse(args[:to])

    import_events_from_source(args[:calendar], from, to)
  end
end

def import_events_from_source(calendar_id, from, to)
  begin
    calendar = Calendar.find(calendar_id)

    puts "Importing events for calendar #{calendar.name} for #{calendar.place.try(:name)}"

    calendar.import_events(Date.today.beginning_of_day, 1.year.from_now)
  rescue => e
    #TODO: Inform admin(s) when this fails
    puts e
    puts e.backtrace
    return
  end
end
