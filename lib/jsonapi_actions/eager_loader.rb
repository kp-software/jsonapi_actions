module JsonapiActions
  class EagerLoader
    attr_reader :records, :serializer, :includes

    # @param records [ActiveRecord::Relation]
    # @param serializer
    # @param includes [Array<Symbol>]
    def initialize(records, serializer, includes)
      @records = records
      @serializer = serializer
      @includes = includes
    end

    # @return [ActiveRecord::Relation]
    def eager_load
      serializer.relationships_to_serialize.each do |rel|
        next if @records.eager_load_values.include?(rel[0])
        @records = @records.eager_load(rel[0])
      end

      includes.each do |rel|
        next if @records.eager_load_values.include?(rel)
        @records = @records.eager_load(rel)
      end

      @records
    end
  end
end