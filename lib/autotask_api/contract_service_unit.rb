module AutotaskAPI
  class ContractServiceUnit < Entity
    self.fields = [ :id, :start_date, :end_date, :service_id, :units ]
  end
end
