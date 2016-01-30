module AutotaskAPI
  class PicklistHelper
    def initialize(client, prefix)
      @prefix = prefix
      @client = client
    end

    def method_missing(method_sym, *arguments, &block)
      pick_key = "#{@prefix}/#{method_sym}"
      entity_name = method_sym.to_s.split('_')[0]

      # require the first part to be a real module
      #('AutotaskAPI::'+entity_name).constantize rescue super
      # maybe when there are more types..

      if @client.picklist.select { |k,v| v.include? pick_key }.count == 0
        @client.get_picklist(entity_name)
      end

      ret = @client.picklist["#{@prefix}/#{method_sym}"]
      super if ret == nil
      ret
    end
  end

  class Client
    def get_picklist(entity_name)
      @@picklist ||= Hash.new
      res = savon_client.call :get_field_info,
        message: "<psObjectType>#{entity_name}</psObjectType>",
        attributes: { xmlns: NAMESPACE }
      res.xpath(
        "//Autotask:Field[./Autotask:IsPickList='true']",
        Autotask: NAMESPACE).collect do |f|
        field_name = f.xpath('./Autotask:Name', Autotask: NAMESPACE).text
        f.xpath('.//Autotask:PickListValue', Autotask: NAMESPACE).collect do |p|
          label = p.xpath('./Autotask:Label', Autotask: NAMESPACE).text
          value = p.xpath('./Autotask:Value', Autotask: NAMESPACE).text
          label = label.gsub(/[^a-zA-Z0-9_]/, '')
          @@picklist["#{basic_auth[0]}/#{entity_name}_#{field_name}_#{label}"] = value
        end
      end
    end

    def pick
      # We're using the username so we can connect to multiple Autotasks
      @helper ||= PicklistHelper.new(self, basic_auth[0])
      @helper
    end

    def pl
      pick
    end

    def picklist
      @@picklist ||= Hash.new
      @@picklist
    end
  end

  class AtQuery
    def get_picklist
      @client.get_picklist(@entity)
    end
  end
end
