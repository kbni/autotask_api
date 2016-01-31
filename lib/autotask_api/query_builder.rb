module AutotaskAPI
  class Client
    def field; @atf ||= EntityQueryFieldHelper.new(false); end
    def udf_field; @atfu ||= EntityQueryFieldHelper.new(true); end
    def fi; @atf ||= EntityQueryFieldHelper.new(false); end
    def ufi; @atfu ||= EntityQueryFieldHelper.new(true); end

    def is_valid_entity(entity_name)
      @valid_entities.keys.include?(entity_name.to_s.downcase)
    end

    def get_entity_query(entity_name)
      if is_valid_entity(entity_name)
        EntityQuery.new(entity_name.to_s, self)
      end
    end

    def method_missing(method_sym, *arguments, &block)
      if is_valid_entity(method_sym)
        get_entity_query(method_sym)
      else
        super
      end
    end
  end

  # Storage object for our XML document
  class EntityQuery
    attr_accessor :client, :entity
    def initialize(entity, client)
      self.entity = entity
      self.client = client
      @doc = XML::Document.new
      @doc.root = XML::Node.new('queryxml')
      @doc.root << (XML::Node.new('entity') << entity.to_s)
      @doc.root << (@query = XML::Node.new('query'))
    end

    def to_s
      rdoc = XML::Document.new
      rdoc.root = XML::Node.new('sXML')
      rdoc.root << XML::Node.new_cdata(@doc.root.to_s)
      rdoc.root.to_s
    end

    def relate_client(expr_or_cond)
      if expr_or_cond.is_a? EntityQueryCondition
        expr_or_cond.children.collect { |c| relate_client(c) }
      elsif expr_or_cond.is_a? EntityQueryExpression
        cmp = expr_or_cond.cmp
        if cmp.is_a? ActiveSupport::TimeWithZone
          expr_or_cond.cmp =
            cmp.in_time_zone('America/New_York').iso8601
        end
      end
      expr_or_cond
    end

    def [](expr_or_cond)
      if expr_or_cond.is_a?(Fixnum)
        @id_cache ||= {}
        if not @id_cache.keys.include?(expr_or_cond)
          @id_cache[expr_or_cond] =
            self[(EntityQueryField.new('id') == expr_or_cond)].first
          @query.children.collect { |c| c.remove! }
          @id_cache[expr_or_cond]
        end
        @id_cache[expr_or_cond]
      elsif expr_or_cond.is_a?(String)
        like_field = (
          ('AutotaskAPI::'+self.entity).constantize.like_field.to_s.camelize or
          "#{self.entity}Name"
        )
        like_field_obj = self.client.field[like_field]
        self[like_field_obj.like(expr_or_cond)]
      else
        @query << relate_client(expr_or_cond.clone).to_xml
        res = @client.entities_for(self.to_s)
        @query.children.collect { |c| c.remove! }
        res
      end
    end

    def query_xml(expr_or_cond)
      if expr_or_cond.is_a?(Fixnum)
        query_xml((EntityQueryField.new('id') == expr_or_cond))
      else
        @query << relate_client(expr_or_cond.clone).to_xml
        res = self.to_s
        @query.children.collect { |c| c.remove! }
        res
      end
    end

    def field_equals(field, cmp)
      self[EntityQueryField.new(field.to_s.camelize, false)==cmp]
    end
  end

  class EntityQueryFieldHelper
    attr_accessor :is_udf
    def initialize(is_udf = false)
      self.is_udf = is_udf
    end

    def method_missing(method_sym, *arguments, &block)
      EntityQueryField.new(method_sym, self.is_udf)
    end

    def [](other)
      EntityQueryField.new(other.to_s, self.is_udf)
    end
  end

  class EntityQueryField
    attr_accessor :name, :is_udf
    def initialize(field_name, is_udf = false)
      self.is_udf = is_udf
      self.name = field_name
    end

    def ==(other)
      EntityQueryExpression.new(self, 'Equals', other)
    end

    def !=(other)
      EntityQueryExpression.new(self, 'NotEqual', other)
    end

    def <(other)
      EntityQueryExpression.new(self, 'LessThan', other)
    end

    def >(other)
      EntityQueryExpression.new(self, 'GreaterThan', other)
    end

    def <=(other)
      EntityQueryExpression.new(self, 'LessThanOrEquals', other)
    end

    def >=(other)
      EntityQueryExpression.new(self, 'GreaterThanOrEquals', other)
    end

    def like(other)
      EntityQueryExpression.new(self, 'Like', other)
    end

    def equals(other)
      EntityQueryExpression.new(self, 'Equals', other)
    end

    def notlike(other)
      EntityQueryExpression.new(self, 'NotLike', other)
    end

    def soundslike(other)
      EntityQueryExpression.new(self, 'SoundsLike', other)
    end

    def isnull
      EntityQueryExpression.new(self, 'IsNull', nil)
    end

    def isnotnull
      EntityQueryExpression.new(self, 'IsNotNull', nil)
    end

    def isthisday(other)
      EntityQueryExpression.new(self, 'IsThisDay', other)
    end

    def contains(other)
      EntityQueryExpression.new(self, 'Contains', other)
    end

    def beginswith(other)
      EntityQueryExpression.new(self, 'BeginsWith', other)
    end

    def endswith(other)
      EntityQueryExpression.new(self, 'EndsWith', other)
    end
  end

  class EntityQueryExpression
    attr_accessor :field, :op, :cmp
    def initialize(field, op, cmp)
      self.field = field.clone
      self.op = op
      self.cmp = cmp
    end

    def |(other)
      if other.is_a?(EntityQueryExpression) || other.is_a?(EntityQueryCondition)
        new_c = EntityQueryCondition.new(self.op)
        new_c << ( EntityQueryCondition.new('and') << self.clone )
        new_c << ( EntityQueryCondition.new('or') << other.clone )
        new_c
      end
    end

    def &(other)
      if other.is_a?(EntityQueryExpression) || other.is_a?(EntityQueryCondition)
        new_c = EntityQueryCondition.new('and')
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

  class EntityQueryCondition
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
      if other.is_a?(EntityQueryExpression) || other.is_a?(EntityQueryCondition)
        new_c = EntityQueryCondition.new('or')
        new_c << self
        new_c << other.clone
        new_c
      end
    end

    def &(other)
      if other.is_a?(EntityQueryExpression) || other.is_a?(EntityQueryCondition)
        new_c = EntityQueryCondition.new('and')
        new_c << self
        new_c << other.clone
        new_c
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
