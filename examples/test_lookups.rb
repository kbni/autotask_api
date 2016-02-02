path_e = File.expand_path(File.dirname(__FILE__)+"/../lib")
$LOAD_PATH.unshift(path_e) unless $LOAD_PATH.include?(path_e)

require 'autotask_api'

client = AutotaskAPI::Client.new do |c|
  c.basic_auth = AUTOTASK_CREDENTIALS
  c.wsdl = AUTOTASK_ENDPOINT
  c.tz = AUTOTASK_TIMEZONE
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

puts ""
puts "#{project.project_number} is managed by "+\
     "#{project.project_lead_resource.full_name}"
puts "#{ticket.ticket_number} is assigned to #{ticket.assigned_resource.full_name}"
puts "#{ticket.number} is in status: "+\
     "#{ticket.status} (#{ticket['status']})"
puts "#{ticket.ticket_number} is in queue: "+\
     "#{ticket.queue} (#{ticket['queue_id']})"
puts "#{account.account_name} is a very lucrative account"
puts "#{resource.full_name} is a kewl dude"

binding.pry rescue nil
