module AutotaskAPI
  class Project < Entity
    self.fields = [ :id, :status, :project_name ]
    has_many :tasks
    has_one :owner, {
      :foreign_key => :project_lead_resource_id,
      :class_name => :resource
    }
  end
end
