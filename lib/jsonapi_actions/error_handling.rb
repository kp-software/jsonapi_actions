# frozen_string_literal: true

module JsonapiActions
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      def bad_request(error)
        render json: { errors: [{ status: 400, title: 'Bad Request', detail: error.message }] }, status: :bad_request
      end

      def record_not_found(error)
        render json: { errors: [{ status: 404, title: 'Not Found', detail: error.message }] }, status: :not_found
      end

      def user_not_authorized(error)
        render json: { errors: [{ status: 403, title: 'Forbidden', detail: error.message }] }, status: :forbidden
      end
    end
  end
end