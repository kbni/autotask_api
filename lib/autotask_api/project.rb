module AutotaskAPI
  class Project < Entity
    self.fields = [ :id, :status, :project_name ]
    self.like_field = :project_name

    has_many :tasks

    def owner
      self.project_lead_resource_id
    end
  end
end
