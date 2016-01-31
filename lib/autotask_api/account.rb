module AutotaskAPI
  class Account < Entity
    self.fields = [ :id, :account_name ]
    self.like_field = :account_name
  end
end
