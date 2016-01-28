module AutotaskAPI
  class Client
    def field
      @atf ||= AtFieldHelper.new(false)
      @atf
    end
    
    def udf_field
      @atfu ||= AtFieldHelper.new(true)
      @atfu
    end
    
    def fi
      @atf ||= AtFieldHelper.new(false)
      @atf
    end
    
    def ufi
      @atfu ||= AtFieldHelper.new(true)
      @atfu
    end
    
    def method_missing(method_sym, *arguments, &block)
      begin
        ('AutotaskAPI::' + method_sym.to_s).constantize
        AtQuery.new(method_sym.to_s, self)
      rescue
        super
      end
    end
  end
  
  # Storage object for our XML document
  class AtQuery
    def initialize(entity, client)
      @client = client
      @doc = XML::Document.new
      @doc.root = XML::Node.new('queryxml')
      @doc.root << (XML::Node.new('entity') << entity.to_s)
      @doc.root << (@query = XML::Node.new('query'))
    end
    
    def entities
      @client.entities_for(self.to_s)
    end
    
    def to_s
      rdoc = XML::Document.new
      rdoc.root = XML::Node.new('sXML')
      rdoc.root << XML::Node.new_cdata(@doc.root.to_s)
      rdoc.root.to_s
    end
    
    def <<(expr_or_cond)
      @query << expr_or_cond.clone.to_xml
      self
    end
    
    def [](expr_or_cond)
      @query << expr_or_cond.clone.to_xml
      self
    end
  end
  
  class AtFieldHelper
    attr_accessor :is_udf
    def initialize(is_udf = false)
      self.is_udf = is_udf
    end
    
    def method_missing(method_sym, *arguments, &block)
      AtField.new(method_sym, self.is_udf)
    end
  end
  
  class AtField
    attr_accessor :name, :is_udf
    def initialize(field_name, is_udf)
      self.is_udf = is_udf
      self.name = field_name
    end
    
    def ==(other)
      AtExpression.new(self, 'Equals', other)
    end
    
    def !=(other)
      AtExpression.new(self, 'NotEqual', other)
    end
    
    def <(other)
      AtExpression.new(self, 'LessThan', other)
    end
    
    def >(other)
      AtExpression.new(self, 'GreaterThan', other)
    end
    
    def <=(other)
      AtExpression.new(self, 'LessThanOrEquals', other)
    end
    
    def >=(other)
      AtExpression.new(self, 'GreaterThanOrEquals', other)
    end
    
    def like(other)
      AtExpression.new(self, 'Like', other)
    end
    
    def equals(other)
      AtExpression.new(self, 'Equals', other)
    end
    
    def notlike(other)
      AtExpression.new(self, 'NotLike', other)
    end
    
    def soundslike(other)
      AtExpression.new(self, 'SoundsLike', other)
    end
    
    def isnull
      AtExpression.new(self, 'IsNull', nil)
    end
    
    def isnotnull
      AtExpression.new(self, 'IsNotNull', nil)
    end
    
    def isthisday(other)
      AtExpression.new(self, 'IsThisDay', other)
    end
    
    def contains(other)
      AtExpression.new(self, 'Contains', other)
    end
    
    def beginswith(other)
      AtExpression.new(self, 'BeginsWith', other)
    end
    
    def endswith(other)
      AtExpression.new(self, 'EndsWith', other)
    end
  end
  
  class AtExpression
    attr_accessor :field, :op, :cmp
    def initialize(field, op, cmp)
      self.field = field.clone
      self.op = op
      self.cmp = cmp
    end
    
    def |(other)
      if other.is_a?(AtExpression) || other.is_a?(AtCondition)
        new_c = AtCondition.new(self.op)
        new_c << ( AtCondition.new('and') << self.clone )
        new_c << ( AtCondition.new('or') << other.clone )
        new_c
      end
    end
    
    def &(other)
      if other.is_a?(AtExpression) || other.is_a?(AtCondition)
        new_c = AtCondition.new('and')
        new_c << self.clone
        new_c << other.clone
        new_c
      end
    end
    
    def to_xml
      f_xml = (XML::Node.new('field') << self.field.name)
      f_xml << (e_xml = XML::Node.new('expression') << self.cmp)
      e_xml['op'] = self.op
      f_xml['udf'] = true.to_s if self.field.is_udf
      f_xml
    end
    
    def to_s
      to_xml
    end
  end
  
  class AtCondition
    attr_accessor :children, :op
    
    def initialize(op)
      self.children = []
      self.op = op
    end
    
    def <<(other)
      self.children << other.clone
      self
    end
    
    def |(other)
      if other.is_a?(AtExpression) || other.is_a?(AtCondition)
        new_c = AtCondition.new('or')
        new_c << self
        new_c << other.clone
        new_c
      end
    end
    
    def &(other)
      if other.is_a?(AtExpression) || other.is_a?(AtCondition)
        self << other.clone
        self
      end
    end
    
    def to_xml
      o_xml = XML::Node.new('condition')
      o_xml['operator'] = 'or' if self.op == 'or'
      self.children.each { |c| o_xml << c.to_xml }
      o_xml
    end
    
    def to_s
      to_xml
    end
  end
end
