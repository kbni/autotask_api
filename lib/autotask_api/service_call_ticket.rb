module AutotaskAPI
  class ServiceCallTicket < Entity
    self.fields = [ :id, :service_call_id, :ticket_id ]
    belongs_to :service_call

    def resource
      self.service_call_ticket_resource
    end
  end
end
