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


simple_lines = [
  "res.count # how many objects were returned",
  "res.first.class # class of the first object",
  "res.first.id # Autotask id of the first object"
]

lookups = [
  {
    code: "client.Project['#{AUTOTASK_TEST_PROJECT}']",
    desc: "Looking up project #{AUTOTASK_TEST_PROJECT}",
    lines: simple_lines + [
      'client.Project[res.first.id].project_name # now search by ID',
      'res.first.tasks.count # how many tasks on project?'
    ]
  },
  {
    code: "client.Account['#{AUTOTASK_TEST_ACCOUNT}']",
    desc: "Looking up account #{AUTOTASK_TEST_ACCOUNT}",
    lines: simple_lines + [
      'client.Account[res.first.id].account_name # now search by ID'
    ]
  },
  {
    code: "client.Resource['#{AUTOTASK_TEST_RESOURCE}']",
    desc: "Looking up resource #{AUTOTASK_TEST_RESOURCE}",
    lines: simple_lines + [
      'client.Resource[res.first.id].full_name # now search by ID'
    ]
  },
  {
    code: "client.Ticket['#{AUTOTASK_TEST_TICKET}']",
    desc: "Looking up ticket #{AUTOTASK_TEST_TICKET}",
    lines: simple_lines + [
      'client.Ticket[res.first.id].ticket_number # now search by ID'
    ]
  }
]

lookups.collect do |lookup|
  puts ">> \# #{lookup[:desc]}"
  puts ">> res = #{lookup[:code]}"
  res = eval(lookup[:code])
  puts res.to_s.split("\n").first[0..30]
  lookup[:lines].collect do |line|
    puts ">> l_res = #{line}"
    l_res = eval(line)
    puts "#{l_res}"
  end
  puts
end