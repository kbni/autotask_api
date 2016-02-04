module AutotaskAPI
  class ServiceCall < Entity
    self.fields = [ :id, :start_date_time, :end_date_time,
                    :account_id, :description ]
  end
end
