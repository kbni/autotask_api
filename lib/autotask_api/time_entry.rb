module AutotaskAPI
  class TimeEntry < Entity
    self.fields = [
      :id, :hours_worked, :resource_id, :internal_notes,
      :summary_notes, :ticket_id, :start_date_time, :end_date_time
    ]
  end
end
