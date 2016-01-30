module AutotaskAPI
  class TimeEntry < Entity
    self.fields = [ :id, :start_date_time, :hours_worked, :resource_id,
                    :internal_notes, :summary_notes, :ticket_id ]

    has_one :resource
    has_one :ticket
  end
end
