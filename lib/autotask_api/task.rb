module AutotaskAPI
  class Task < Entity
    self.fields = [
      :id, :task_number, :title, :description
    ]
    def complete?
      self.attributes[:completeddatetime].to_s != ""
    end
  end
end
