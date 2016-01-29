module AutotaskAPI
  class Task < Entity
    self.fields = [
      :id, :task_number, :title, :description
    ]
    def complete?
      self[:completed_datetime].to_s != ""
    end
  end
end
