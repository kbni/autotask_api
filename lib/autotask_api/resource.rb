module AutotaskAPI
  class Resource < Entity
    self.fields = [ :id, :email, :first_name, :last_name, :user_name, :active ]
    self.like_field = :user_name
    self.find_by = [ :email, :user_name ]

    def full_name
      [ first_name, last_name ].join(' ')
    end

    def firstname_lastname_initial
      "#{first_name} #{last_name[0]}."
    end

    def active?
      active.to_s == 'true'
    end
  end
end
