module AutotaskAPI
  class Entity
    class_attribute :fields, :client, :find_cache
    attr_accessor :attributes, :raw_xml

    def initialize(xml, client)
      self.client = client
      self.raw_xml = xml
      self.attributes = {}
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

    def method_missing(method, *args, &block)
      attr_name = method.to_s.gsub('_', '').downcase
      ret = field_by_xpath(attr_name, nil)
      if ret == nil
        super
      else
        if attr_name.include? "datetime"
          if ret.include? "T00:00:00"
            ret = ActiveSupport::TimeZone[self.client.tz].parse(ret)
          else
            ret = ActiveSupport::TimeZone['America/New_York'].parse(ret)
            ret = ret.in_time_zone(self.client.tz)
          end
        end
        ret
      end
    end

    def self.find(id, field = 'id')
      raise "No initialized client!" unless client
      self.find_cache ||= {}

      query = AutotaskAPI::QueryXML.new do |query|
        query.entity = self.to_s.demodulize
        query.field = field
        query.expression = id
      end
      find_cache[id] ||= client.entities_for(query).first
    end

    def self.belongs_to(name, options = {})
      name = name.to_s
      klass = "AutotaskAPI::#{(options[:class_name] || name).to_s.classify}"
      foreign_key = name.foreign_key
      define_method name do
        klass.constantize.find send(foreign_key)
      end
    end

    def self.has_one(name, options = {})
      name = name.to_s
      options.reverse_merge! foreign_key: self.to_s.foreign_key.camelize
      klass = "AutotaskAPI::#{(options[:class_name] || name).to_s.classify}"
      define_method name do
        klass.constantize.find id, options[:foreign_key]
      end
    end
  end
end
