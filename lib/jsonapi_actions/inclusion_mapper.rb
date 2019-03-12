module JsonapiActions
  class InclusionMapper
    attr_reader :map

    def initialize(serializer, include = '*')
      @included = []
      @recursive = include == '**'
      @map = include_relationships(serializer)
    end

    private

      def include_relationships(serializer, parent_key: nil)
        include = []

        serializer.relationships_to_serialize&.each do |k, v|
          child_serializer = v.serializer.to_s.safe_constantize
          next if child_serializer.nil? || @included.include?(child_serializer)

          child_key = parent_key ? "#{parent_key}.#{k}".to_sym : k
          include << child_key
          @included << child_serializer

          next unless @recursive
          include << include_relationships(child_serializer, parent_key: child_key)
        end

        Rails.logger.info "Including: #{include.join(', ')}"
        include.flatten.compact
      end
  end
end