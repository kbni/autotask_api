module AutotaskAPI
  class Service < Entity
    self.fields = [ :id, :is_active, :name ]
    self.like_field = :name

    def csu_current
      client.ContractServiceUnit[
        (client.field.ServiceID==self.id) & (
          (client.field.start_date <= client.now) &
          (client.field.end_date >= client.now)
        )
      ]
    end

    def active?
      is_active.to_s == 'true'
    end
  end
end
