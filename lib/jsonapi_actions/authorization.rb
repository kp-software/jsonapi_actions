module JsonapiActions
  module Authorization
    extend ActiveSupport::Concern

    if !Gem::Specification.find_by_name('pundit')
      def policy_scope(scope)
        scope
      end

      def policy(record)
        OpenStruct.new(permitted_attributes: permitted_attributes)
      end

      def permitted_attributes
        []
      end

      def authorize(record, query = nil)
        # do nothing
      end
    end
  end
end