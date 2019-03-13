require 'active_support/concern'

require 'jsonapi_actions/authorization'
require 'jsonapi_actions/error_handling'
require 'jsonapi_actions/inclusion_mapper'
require 'jsonapi_actions/version'

module JsonapiActions
  extend ActiveSupport::Concern

  included do
    include ErrorHandling
    include Authorization

    # The model's Class OR the class name
    self.model = nil
    self.serializer = nil
    self.model_name = 'ApplicationRecord'

    # defines a set of parent associations to scope the index result by
    # i.e.  [{ param: :project_id, attribute: :project_id }]
    #       OR [{ param: :project_id, association: :project }]
    self.parent_associations = []

    before_action :set_record, only: %i[show update destroy]

    def index
      authorize model, :index?
      @records = policy_scope(model.all)
      @records = parent_scope(@records)
      @records = filter(@records)
      @records = sort(@records)
      @records = paginate(@records)
      @records = eager_load(@records)

      render json_response(@records, meta: pagination_meta(@records).merge(metadata))
    end

    def show
      render json_response(@record)
    end

    def create
      @record = model.new
      @record.assign_attributes(record_params)
      @record.id = id_param if id_param
      authorize(@record)

      if @record.save
        @record.reload # ensure we have after commit stuff from things like carrierwave
        render json_response(@record, status: :created)
      else
        render unprocessable_entity(@record)
      end
    end

    def update
      if @record.update(record_params)
        @record.reload # ensure we have after commit stuff from things like carrierwave
        render json_response(@record)
      else
        render unprocessable_entity(@record)
      end
    end

    def destroy
      if @record.destroy
        render json: {}, status: 204
      else
        render unprocessable_entity(@record)
      end
    end

    private

    def metadata
      {}
    end

    def parent_scope(records)
      return records if self.class.parent_associations.blank?

      self.class.parent_associations.each do |parent|
        next if params[parent[:param]].blank?

        records = records.joins(parent[:association]) unless parent[:association].blank?
        records = if parent[:table]
                    records.where(parent[:table] => { parent[:attribute] => params[parent[:param]] })
                  else
                    records.where(parent[:attribute] => params[parent[:param]])
                  end
      end

      records
    end

    def filter(records)
      records
    end

    def sort(records)
      return records if params[:sort].blank?
      order = {}

      params[:sort].split(',').each do |sort|
        if sort[0] == '-'
          order[sort[1..-1]] = :desc
        else
          order[sort] = :asc
        end
      end

      return records.order(order)
    end

    def paginate(records)
      records.page(page[:number]).per(page[:size])
    end

    def page
      @page ||= begin
        page = {}
        page[:number] = (params.dig(:page, :number) || 1).to_i
        page[:size] = [[(params.dig(:page, :size) || 20).to_i, 1000].min, 1].max
        page
      end
    end

    def set_record
      @record = model.find(params[:id])
      authorize(@record)
    end

    def id_param
      params.require(:data).permit(policy(@record).permitted_attributes)[:id]
    end

    def record_params
      params.require(:data).require(:attributes).permit(policy(@record).permitted_attributes)
    end

    def include_param
      if %w[* **].include? params[:include]
        inclusion_map
      else
        params[:include].to_s.split(',').reject(&:blank?).map(&:to_sym)
      end
    end

    def inclusion_map
      InclusionMapper.new(serializer, params[:include]).map
    end

    def unprocessable_entity(record)
      Rails.logger.debug(record.errors.messages)
      { json: record.errors.messages, status: :unprocessable_entity }
    end

    def pagination_meta(collection)
      return {} if collection.nil?

      {
        current_page: collection.current_page,
        next_page: collection.next_page,
        prev_page: collection.prev_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count
      }
    end

    def model
      self.class.model || self.class.model_name.constantize
    end

    def json_response(data, options = {})
      if defined?(FastJsonapi)
        {
          json: serializer.new(data, options.deep_merge(params: {
            meta: metadata, include: include_param, current_user: current_user
          }))
        }

      elsif defined?(ActiveModel::Serializer)
        { json: data }.merge(meta: metadata, include: include_param).merge(options)

      else
        { json: { data: data }.merge(options) }
      end
    end

    def serializer
      self.class.serializer || "#{model.name}Serializer".constantize
    end

    def eager_load(records)
      records
    end

    # Pundit Usage
    if !defined?(Pundit)
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

  module ClassMethods
    attr_accessor :model, :parent_associations, :permitted_params, :model_name, :serializer
  end
end
