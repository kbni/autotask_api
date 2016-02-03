module AutotaskAPI
  class Entity
    class_attribute :fields, :like_field, :find_by, :client
    attr_accessor :attributes, :raw_xml

    def initialize(xml, client)
      self.client = client
      self.raw_xml = xml
      self.attributes = {}
      @entity_name = self.class.to_s.demodulize
      fields.each do |field|
        attributes[field] = self[field]
      end
    end

    def field_by_xpath(attr_name, rescue_val = '')
      field_node_name = attr_name.to_s.downcase.gsub('_', '')
      xpath_query = "*[translate(name(),"\
        "'ABCDEFGHIJKLMNOPQRSTUVWXYZ',"\
        "'abcdefghijklmnopqrstuvwxyz')"\
        "='#{field_node_name}']"
      raw_xml.at_xpath(xpath_query).text.strip rescue rescue_val
    end

    def [](attr_name)
      field_by_xpath(attr_name, '')
    end

    def self.valid_field?(field_name)
      self.fields.include?(field_name.to_sym)
    end

    def self.belongs_to(name, options = {})
      class_name = (options[:class_name] || name).to_s
      foreign_key = (options[:foreign_key] || class_name.foreign_key).to_s
      define_method name do
        use_key = self[foreign_key]
        if use_key != ''
          self.client.get_entity_query(class_name)[use_key.to_i]
        end
      end
    end

    def self.has_many(name, options = {})
      class_name = (options[:class_name] || name.to_s.gsub(/s$/, '')).to_s
      foreign_key = (options[:foreign_key] || self.name.demodulize+'_id').to_s
      define_method name do
        self.client.get_entity_query(class_name.camelize).\
          field_equals(foreign_key, self.id)
      end
    end

    def self.has_one(name, options = {})
      class_name = (options[:class_name] || name).to_s
      foreign_key = (options[:foreign_key] || class_name.foreign_key).to_s
      define_method name do
        use_key = self[foreign_key]
        if use_key != ''
          self.client.get_entity_query(class_name)[use_key.to_i]
        end
      end
    end
  end
end
