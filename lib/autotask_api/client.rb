module AutotaskAPI
  class Client
    NAMESPACE = 'http://autotask.net/ATWS/v1_5/'
    attr_accessor :savon_client, :wsdl, :basic_auth, :query, :log, :tz

    def initialize
      yield self
      self.savon_client ||= Savon.client do |c|
        c.basic_auth basic_auth
        c.wsdl wsdl
        c.pretty_print_xml true
        c.log !!log
        c.read_timeout 30
        c.open_timeout 30
      end

      @valid_entities = Hash.new
      AutotaskAPI.constants.collect do |const|
        if ('AutotaskAPI::'+const.to_s).constantize.superclass == Entity
          @valid_entities[const.to_s.downcase] = const
        end
      end

      self.tz ||= 'UTC'
    end

    def now
      ActiveSupport::TimeZone[tz].now
    end

    def response
      savon_client.call :query, message: query,
        attributes: { xmlns: NAMESPACE }
    end

    def update(xml)
      savon_client.call :update, message: "<Entities>#{xml}</Entities>",
        attributes: { xmlns: NAMESPACE }
    end

    def create(xml)
      savon_client.call :create, message: "<Entities>#{xml}</Entities>",
        attributes: { xmlns: NAMESPACE }
    end

    def entities_for(query)
      self.query = query

      entities = response.xpath '//Autotask:Entity',
        Autotask: NAMESPACE

      return [] if entities.blank?

      klass = entity_class(entities.first.attribute('type').to_s)
      entities.collect do |entity|
        klass.new(entity, self)
      end
    end

    def entity_class(entity_name)
      ('AutotaskAPI::' + entity_name.to_s.camelize).constantize rescue false
    end

    def field_info(entity_name)
      savon_client.call :get_field_info, message: { psObjectType: entity_name }
    end

    def udf_info(entity_name)
      savon_client.call :get_udf_info, message: { psTable: entity_name }
    end

    def zone_info(user_name = nil)
      savon_client.call :get_zone_info,
        message: { 'UserName' => user_name || basic_auth.first }
    end
  end
end
