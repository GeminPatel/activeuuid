module UUIDTools
  class UUID
    # monkey-patch Friendly::UUID to serialize UUIDs to MySQL
    def quoted_id
      s = raw.unpack("H*")[0]
      "x'#{s}'"
    end

    def as_json(options = nil)
      hexdigest.upcase
    end

    def to_param
      hexdigest.upcase
    end
  end
end

module Arel
  module Visitors
    class DepthFirst < Arel::Visitors::Visitor
      def visit_UUIDTools_UUID(o)
        o.quoted_id
      end
    end
    class MySQL < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o)
        o.quoted_id
      end
    end

    class SQLite < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o)
        o.quoted_id
      end
    end
  end
end

module ActiveUUID
  class UUIDSerializer
    def load(binary)
      case binary
      when UUIDTools::UUID
        binary
      when String
        parse_string(binary)
      when nil
        nil
      else
        raise TypeError, "the given type cannot be serialized"
      end
    end

    def dump(uuid)
      case uuid
      when UUIDTools::UUID
        uuid.raw
      when String
        parse_string(uuid).raw
      when nil
        nil
      else
        raise TypeError, "the given type cannot be serialized"
      end
    end

    private

    def parse_string str
      if str.length == 36
        UUIDTools::UUID.parse str
      elsif str.length == 32
        UUIDTools::UUID.parse_hexdigest str
      else
        UUIDTools::UUID.parse_raw str
      end
    end
  end

  module UUID
    extend ActiveSupport::Concern

    included do
      uuids :id
    end

    module ClassMethods
      def natural_key_attributes
        @_activeuuid_natural_key_attributes
      end

      def natural_key(*attributes)
        @_activeuuid_natural_key_attributes = attributes
      end

      def uuids(*attributes)
       attributes.each do |attribute|
          serialize attribute.intern, ActiveUUID::UUIDSerializer.new
         #class_eval <<-eos
         #  # def #{@association_name}
         #  #   @_#{@association_name} ||= self.class.associations[:#{@association_name}].new_proxy(self)
         #  # end
         #eos
       end
      end
    end

    module InstanceMethods
    end
 
  end
end
