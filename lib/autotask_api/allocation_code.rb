module AutotaskAPI
  class AllocationCode < Entity
    self.fields = [ :name, :description, :department, :active ]
    self.like_field = :name
  end
end
