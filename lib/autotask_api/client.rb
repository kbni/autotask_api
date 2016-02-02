module AutotaskAPI
  class Client
    NAMESPACE = 'http://autotask.net/ATWS/v1_5/'
    attr_accessor :savon_client, :wsdl, :basic_auth, :query, :log, :tz, :cache_dir

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

      self.cache_dir ||= false
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

    def field_info(entity_name, as_hash = false)
      if as_hash == false
        return savon_client.call :get_field_info, message: { psObjectType: entity_name }
      end

      cache_key = "get_field_info.#{entity_name}"
      cached_fields = cache_load(cache_key)

      return cached_fields if cached_fields != false

      res = savon_client.call :get_field_info, message: { psObjectType: entity_name }
      fields =
        res.xpath('//Autotask:Field', Autotask: NAMESPACE).collect do |f|
          ns = { Autotask: NAMESPACE }
          field = {
            udf: false,
            name: f.xpath('./Autotask:Name', ns).text,
            label: f.xpath('./Autotask:Label', ns).text,
            type: f.xpath('./Autotask:Type', ns).text.underscore,
            length: f.xpath('./Autotask:Length', ns).text.to_i,
            is_read_only: f.xpath('./Autotask:IsReadOnly', ns).text == 'true',
            is_queryable: f.xpath('./Autotask:IsQueryable', ns).text == 'true',
            is_reference: f.xpath('./Autotask:IsReference', ns).text == 'true',
            is_required: f.xpath('./Autotask:IsRequired', ns).text == 'true',
            is_picklist: f.xpath('./Autotask:IsPickList', ns).text == 'true'
          }

          if field[:is_reference]
            field.update({
              ref_entity_type: f.xpath('./Autotask:ReferenceEntityType', ns)
              .text.underscore
            })
          end

          if field[:is_picklist]
            field.update({
              picklist_parent:
                f.xpath('./Autotask:PicklistParentValueField', ns).text == 'true',
              picklist: f.xpath('.//Autotask:PickListValue', ns).collect do |p|
                [
                  p.xpath('./Autotask:Label', ns).text,
                  p.xpath('./Autotask:Value', ns).text
                ]
              end
            })
          end

          field
        end

      cache_save(cache_key, fields)
    end

    def udf_info(entity_name, as_hash = false)
      if as_hash == false
        return savon_client.call :get_udf_info, message: { psTable: entity_name }
      end

      cache_key = "get_udf_info.#{entity_name}"
      cached_fields = cache_load(cache_key)

      return cached_fields if cached_fields != false

      res = savon_client.call :get_udf_info, message: { psTable: entity_name }
      fields =
        res.xpath('//Autotask:Field', Autotask: NAMESPACE).collect do |f|
          ns = { Autotask: NAMESPACE }
          field = {
            udf: true,
            name: f.xpath('./Autotask:Name', ns).text,
            label: f.xpath('./Autotask:Label', ns).text,
            type: f.xpath('./Autotask:Type', ns).text.underscore,
            length: f.xpath('./Autotask:Length', ns).text.to_i,
            is_read_only: f.xpath('./Autotask:IsReadOnly', ns).text == 'true',
            is_queryable: f.xpath('./Autotask:IsQueryable', ns).text == 'true',
            is_reference: f.xpath('./Autotask:IsReference', ns).text == 'true',
            is_required: f.xpath('./Autotask:IsRequired', ns).text == 'true',
            is_picklist: f.xpath('./Autotask:IsPickList', ns).text == 'true'
          }

          if field[:is_reference]
            field.update({
              ref_entity_type: f.xpath('./Autotask:ReferenceEntityType', ns)
              .text.underscore
            })
          end

          if field[:is_picklist]
            field.update({
              picklist_parent:
                f.xpath('./Autotask:PicklistParentValueField', ns).text == 'true',
              picklist: f.xpath('.//Autotask:PickListValue', ns).collect do |p|
                [
                  p.xpath('./Autotask:Label', ns).text,
                  p.xpath('./Autotask:Value', ns).text
                ]
              end
            })
          end

          field
        end

      cache_save(cache_key, fields)
    end

    def zone_info(user_name = nil)
      savon_client.call :get_zone_info,
        message: { 'UserName' => user_name || basic_auth.first }
    end

    def cache_path(item_name)
      return false if not self.cache_dir
      File.expand_path(self.cache_dir + "/#{basic_auth.first}-#{item_name}.yml")
    end

    def cache_load(item_name)
      cache_path = cache_path(item_name)
      return false unless cache_path
      return false unless File.exists?(cache_path)
      YAML.load(File.read(cache_path))
    end

    def cache_save(item_name, item)
      cache_path = cache_path(item_name)
      if cache_path
        File.open(cache_path, 'w') { |f| f.write(YAML.dump(item)) }
      end
      item
    end
  end
end
