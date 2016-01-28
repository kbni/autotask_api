module AutotaskAPI
  class Project < Entity
    self.fields = [
      :id, :status, :project_name
    ]
  end
end
