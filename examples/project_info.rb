path_e = File.expand_path(File.dirname(__FILE__)+"/../lib")
$LOAD_PATH.unshift(path_e) unless $LOAD_PATH.include?(path_e)

require 'autotask_api'

TIMEZONE rescue TIMEZONE='Australia/Brisbane'

def active_resources(at)
  ar = Hash.new
  at.Resource[at.field.Active==true].entities.collect do |r|
    ar[r.id] = [ r.user_name, "#{r.first_name} #{r.last_name}" ]
  end
  ar
end

def autotask_project(at, proj_name)
  proj = at.Project[at.field.ProjectName.beginswith(proj_name)].entities.first
  return nil unless proj
  tasks = at.Task[at.field.ProjectID==proj.id].entities
  return nil unless tasks.count > 0
  
  at_resources = active_resources(at)
  
  proj_data = {
    name: proj.project_name,
    owner: at_resources[proj[:project_lead_resource_id]][-1],
    task_count: { total: 0, complete: 0 },
    hour_count: { total: 0, complete: 0 },
    up_to_perc: 0,
    desire_perc: 0
  }
  tasks.collect do |task|
    proj_data[:task_count][:total] += 1.to_f
    proj_data[:hour_count][:total] += task[:estimated_hours].to_f
    if task.complete?
      proj_data[:task_count][:complete] += 1.to_f
      proj_data[:hour_count][:complete] += task[:estimated_hours].to_f
    end
  end
  
  proj_start = Time.parse(proj[:startdatetime]).in_time_zone(TIMEZONE)
  proj_end = Time.parse(proj[:enddatetime]).in_time_zone(TIMEZONE)
  proj_elapsed = Time.now.in_time_zone(TIMEZONE) - proj_start
  proj_len = proj_end - proj_start
  
  proj_timeframe = 0.to_f
  up_to_seconds = 0.to_f
  tasks.collect do |task|
    task_timeframe = task[:estimated_hours].to_f*3600
    task_remaining = task[:remaining_hours].to_f*3600
    proj_timeframe += task_timeframe
    
    if task.complete?
      up_to_seconds += task_timeframe
    elsif task_remaining > 0
      up_to_seconds += task_timeframe - task_remaining
    else
      up_to_seconds += task_timeframe / 2
    end
  end
  
  proj_data.update({
    proj_timeframe: proj_timeframe.to_f,
    up_to_seconds: up_to_seconds.to_f
  })
  
  if proj_timeframe > 0
    proj_data[:up_to_perc] = [100,(up_to_seconds.to_f / proj_timeframe.to_f)*100].min
  end
  if proj_len > 0
    proj_data[:desire_perc] = [100,(proj_elapsed.to_f / proj_len.to_f)*100].min
  end
  
  proj_data
end

client = AutotaskAPI::Client.new do |c|
  c.basic_auth = AUTOTASK_CREDENTIALS
  c.wsdl = AUTOTASK_ENDPOINT
  c.log = false
end

# Search for a project and output some information
proj_data = autotask_project(client, "Script Development")
puts proj_data
