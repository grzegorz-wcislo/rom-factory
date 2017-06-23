require 'delegate'

module ROM::Factory
  class Builder
    attr_reader :schema, :relation, :model, :default_attrs

    def initialize(schema, relation)
      @schema = schema
      @relation = relation
      @model = relation.with(auto_struct: true).mapper.model
      @sequence = 0
      @default_attrs = relation.schema.each_with_object({}) { |a, h|
        h[a.name] = nil
      }
    end

    def tuple(attrs)
      input_schema.(schema.map { |k, v| [k, v.call] }.to_h.merge(attrs))
    end

    def create(attrs = {})
      struct(tuple(attrs.merge(primary_key => next_id)))
    end

    def struct(attrs)
      model.new(default_attrs.merge(attrs))
    end

    def persistable
      Persistable.new(self)
    end

    def primary_key
      relation.primary_key
    end

    def input_schema
      relation.input_schema
    end

    private

    def next_id
      @sequence += 1
    end
  end

  class Persistable < SimpleDelegator
    attr_reader :builder, :relation

    def initialize(builder, relation = builder.relation)
      super(builder)
      @builder = builder
      @relation = relation
    end

    def create(attrs = {})
      tuple = builder.tuple(attrs)
      result = relation.command(:create).call(tuple)

      struct(result)
    end
  end
end
