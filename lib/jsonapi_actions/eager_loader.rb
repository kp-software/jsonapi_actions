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
      serializer.relationships_to_serialize&.each do |rel|
        next if @records.eager_load_values.include?(rel[0])
        @records = @records.eager_load(rel[0])
      end

      includes.each do |include|
        rel = path_to_relationship(include.to_s.split('.'))
        next if @records.eager_load_values.include?(rel)
        @records = records.eager_load(rel)
      end

      @records
    end

    private

      def path_to_relationship(parts)
        if parts.length == 1
          parts[0].to_sym
        else parts.length == 2
        { parts[0].to_sym => path_to_relationship(parts[1..-1]) }
        end
      end
  end
end