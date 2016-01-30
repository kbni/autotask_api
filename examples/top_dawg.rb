path_e = File.expand_path(File.dirname(__FILE__)+"/../lib")
$LOAD_PATH.unshift(path_e) unless $LOAD_PATH.include?(path_e)

require 'autotask_api'

def today_time_entries(at)
  week_day = at.now
  week_day -= 1.day if week_day.saturday?
  week_day -= 2.day if week_day.sunday?

  today_se = (
    (at.fi.StartDateTime >= week_day.change({ hour:0, min: 0 })) &
    (at.fi.StartDateTime <= week_day.change({ hour: 23, min: 59 }))
  )
  tech_work = (
    (at.fi.AllocationCodeID != at.pl.ExpenseItem_WorkType_GeneralAdministration) &
    (at.fi.AllocationCodeID != at.pl.ExpenseItem_WorkType_Sales)
  )

  at.TimeEntry[today_se&tech_work]
end

client = AutotaskAPI::Client.new do |c|
  c.basic_auth = AUTOTASK_CREDENTIALS
  c.wsdl = AUTOTASK_ENDPOINT
  c.tz = AUTOTASK_TIMEZONE
  c.log = false
end

time_entries = today_time_entries(client)

puts "#{time_entries.count} time entries from last work day"

time_entries.collect do |te|
  puts "#{te.start_date_time} to #{te.end_date_time}"
  puts te
end

binding.pry rescue nil
