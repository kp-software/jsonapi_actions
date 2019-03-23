module JsonapiActions
  class InclusionMapper
    attr_reader :map, :root

    def initialize(serializer, include: '*')
      @included = {}
      @recursive = include == '**'
      @root = serializer.record_type
      @map = include_relationships(serializer)
    end

    private

      # TODO: figure out how to avoid joining an existing relationship;
      #   community.units.projects.features.room.project.project_services.features.feature_images
      #     SHOULD BE  community.units.projects.features.room
      def include_relationships(serializer, parent_key: nil)
        include = []

        serializer.relationships_to_serialize&.each do |k, v|
          child_serializer = v.serializer.to_s.safe_constantize
          next if child_serializer.nil? ||
            included?(serializer.record_type, child_serializer.record_type) ||
            parent_key.to_s.include?("#{k}.") ||
            parent_key.to_s.include?("#{k.to_s.pluralize}.")

          child_key = parent_key ? "#{parent_key}.#{k}".to_sym : k
          include << child_key

          @included[serializer.record_type] << child_serializer.record_type

          next unless @recursive
          include << include_relationships(child_serializer, parent_key: child_key)
        end

        include
      end

      def included?(parent, child)
        return true if parent == child

        @included[parent] ||= []
        @included[child] ||= []

        @included[parent].include?(child)
      end
  end
end