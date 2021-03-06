path_e = File.expand_path(File.dirname(__FILE__)+"/../lib")
$LOAD_PATH.unshift(path_e) unless $LOAD_PATH.include?(path_e)

require 'autotask_api'

client = AutotaskAPI::Client.new do |c|
  c.basic_auth = AUTOTASK_CREDENTIALS
  c.wsdl = AUTOTASK_ENDPOINT
  c.tz = AUTOTASK_TIMEZONE
  c.cache_dir = AUTOTASK_CACHE_DIR
  c.log = false
end

# Personally, I define these in a module included with ruby -r
AUTOTASK_TEST_PROJECT ||= 'Some Project' # Lookup a project by this name
AUTOTASK_TEST_ACCOUNT ||= 'Big Account' # Lookup an account by this name
AUTOTASK_TEST_RESOURCE ||= 'aperson' # Look up a resource by this username
AUTOTASK_TEST_TICKET ||= 'T20160121.0104' # Lookup a ticket by ticket number

test_entities = {
  project: client.Project[AUTOTASK_TEST_PROJECT].first,
  account: client.Account[AUTOTASK_TEST_ACCOUNT].first,
  resource: client.Resource[AUTOTASK_TEST_RESOURCE].first,
  ticket: client.Ticket[AUTOTASK_TEST_TICKET].first
}

test_entities.collect do |name,ent|
  if ent == nil
    raise("Unable to load entity for #{name}")
  else
    puts "Loaded #{ent} for #{name}"
  end
end

project = test_entities[:project]
account = test_entities[:account]
resource = test_entities[:resource]
ticket = test_entities[:ticket]

last_week = (
  (client.fi.start_date_time >= (client.now.change({hour:0,min:0})-7.day)) &
  (client.fi.start_date_time <= client.now.change({hour:23,min:59}))
)
tech_work = (
  (client.fi.allocation_code != 'General Administration') &
  (client.fi.allocation_code != 'Sales')
)

puts ""
puts "#{project.project_number} is managed by "+\
     "#{project.project_lead_resource.full_name}"
puts "#{ticket.ticket_number} is assigned to #{ticket.assigned_resource.full_name}"
puts "#{ticket.number} is in status: "+\
     "#{ticket.status} (#{ticket['status']})"
puts "#{ticket.number} has #{ticket.time_entries.count} time entries"
puts "#{ticket.ticket_number} is in queue: "+\
     "#{ticket.queue} (#{ticket['queue_id']})"
puts "#{account.account_name} is a very lucrative account"
puts "#{resource.full_name} is a kewl dude"

te_last_week = client.TimeEntry[last_week&tech_work]
first_te = nil
last_te = nil

puts "There were #{te_last_week.count} time entries in the last 7 days"

binding.pry rescue nil
