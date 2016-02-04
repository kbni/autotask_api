path_e = File.expand_path(File.dirname(__FILE__)+"/../lib")
$LOAD_PATH.unshift(path_e) unless $LOAD_PATH.include?(path_e)

require 'autotask_api'

def top_dawg(at)
  week_day = at.now
  week_day -= 1.day if week_day.saturday?
  week_day -= 2.day if week_day.sunday?

  today_se = (
    (at.fi.start_date_Time >= week_day.change({ hour:0, min: 0 })) &
    (at.fi.start_date_Time <= week_day.change({ hour: 23, min: 59 }))
  )
  tech_work = (
    (at.fi.allocation_code != 'General Administration') &
    (at.fi.allocation_code != 'Sales')
  )

  time_entries = at.TimeEntry[today_se&tech_work]

  dawgs = Hash.new
  time_entries.collect do |te|
    resource = te.resource
    dawgs[resource.id] ||= 0.to_f
    dawgs[resource.id] += te.hours_worked
  end

  td = Hash[dawgs.select { |k,v| v == dawgs.values.max }]

  txt =
    if td.count > 1
      "There are #{td.count} Top Dawgs at #{td.values.max} hours: "+
      ", ".join(td.keys.collect { |r| at.Resource[r].full_name })
    elsif td.count == 1
      "The Top Dawg on #{td.values.max} hours is "+
      "#{at.Resource[td.keys.max].full_name}"
    else
      "There is currently no Top Dawg. Take the title."
    end

  { value: td.values.max || 0.to_f, moreinfo: txt }
end

client = AutotaskAPI::Client.new do |c|
  c.basic_auth = AUTOTASK_CREDENTIALS
  c.wsdl = AUTOTASK_ENDPOINT
  c.tz = AUTOTASK_TIMEZONE
  c.log = false
end

dawgs = top_dawg(client)
puts dawgs

binding.pry rescue nil
