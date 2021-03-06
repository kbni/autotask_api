module AutotaskAPI
  class Ticket < Entity
    self.fields = [ :account_id, :assigned_resource_id, :ticket_number, :title, :description, :status ]
    self.like_field = :ticket_number

    def time_entries
      client.TimeEntry[client.field.TicketID==self.id]
    end

    def status_name
      self.class.status_map[status]
    end

    def self.status_map
      @status_map ||= client.field_info(self.to_s.demodulize).
        xpath('//AT:Field/AT:Name[text()="Status"]/..//AT:PickListValue',
             AT: Client::NAMESPACE).
             inject({}) do |memo, node|
        value, label = node.xpath('(AT:Value | AT:Label)/text()',
                                 AT: Client::NAMESPACE).collect(&:to_s)
        memo[value] = label
        memo
      end
    end
  end
end
