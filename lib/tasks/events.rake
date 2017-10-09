namespace :import do

  #No data for calendar of type `other` right now. 
  task all_events: :environment do
    Calendar.without_type(:other).each do |calendar|
      import_events_from_source(calendar.id, Date.current.beginning_of_day)
    end
  end

  task :events_from_source, [:calendar_id] => [:environment] do |t, args|
    import_events_from_source(args[:calendar_id], Date.current.beginning_of_day)
  end


  #calendar_id - object id of calendar to be imported.
  #from - import events starting from this date. Must use format 'dd-mm-yy'.
  #to - import events up until this date. Must use format 'dd-mm-yy' and must be greater than from date.

  task :past_events_from_source, [:calendar_id, :from] => [:environment] do |t, args|
    from = DateTime.parse(args[:from])

    import_events_from_source(args[:calendar_id], from)
  end
end

def import_events_from_source(calendar_id, from)
  begin
    calendar = Calendar.find(calendar_id)

    puts "Importing events for calendar #{calendar.name} for #{calendar.place.try(:name)}"

    calendar.import_events(from)
  rescue => e
    #TODO: Inform admin(s) when this fails
    puts e
    puts e.backtrace
    return
  end
end
