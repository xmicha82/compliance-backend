# frozen_string_literal: true

module V2
  class ApplicationController < ::ActionController::API
    def render_json(collection, **args)
      render({ json: serializer.new(collection, serializer_opts) }.merge(args))
    end

    private

    def serializer_opts
      # opts = index? ? metadata : {}
      # opts.merge!(params: { root_resource: resource, action: action_name })
      # opts[:params].merge!(relationships: relationships_enabled?)
      # opts.merge!(include: include_params.split(',')) if include_params

      {}
    end

    def index?
      ['index'].include?(action_name)
    end

    def serializer
      raise NotImplementedError
    end
  end
end
