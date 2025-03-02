# frozen_string_literal: true

module V2
  # Reusable parameter checking for all controllers
  module ParameterHandling
    extend ActiveSupport::Concern

    # Constraint validating parent (belongs_to) reflections passed via params[:parents]
    class SymbolConstraint < StrongerParameters::Constraint
      def value(val)
        return val if val.is_a?(Symbol)

        StrongerParameters::InvalidValue.new(val, 'is not permitted')
      end
    end

    # Constraint validating UUIDs passed via params[:*_id]
    class UUIDConstraint < StrongerParameters::Constraint
      def value(val)
        return val if UUID.validate(val)

        StrongerParameters::InvalidValue.new(val, 'is not permitted')
      end
    end

    ParamType = ActionController::Parameters # shorthand
    ID_TYPE = ParamType.integer | ParamType.string
    ParamType.action_on_unpermitted_parameters = :raise # fail on unpermitted params

    DEFAULT_PERMITTED = StrongerParameters::ControllerSupport::PermittedParameters::DEFAULT_PERMITTED.merge(
      _json: ParamType.nil,
      # The list of parents should come from the routed resource definition as an
      # array of Symbols. The custom constraint prevents passing this param as a
      # regular parameter as it is not possible to pass Symbols as HTTP params.
      parents: ParamType.array(SymbolConstraint.new)
    )

    class_methods do
      attr_accessor :__permitted_params_for_action

      private

      # Configuring a list of permitted params for a given controller action
      def permitted_params_for_action(action, params)
        self.__permitted_params_for_action ||= {}
        self.__permitted_params_for_action[action] = params
      end
    end

    included do
      permitted_params_for_action :index, {
        limit: ParamType.integer & ParamType.gt(0) & ParamType.lte(100),
        offset: ParamType.integer & ParamType.gte(0),
        sort_by: ParamType.array(ParamType.string) | ParamType.string,
        filter: ParamType.string
      }

      permitted_params_for_action :show, id: ParamType.string

      # FIXME: compatibility with the V1 logic from the common concerns
      def relationships_enabled?
        false
      end

      # FIXME: compatibility with the V1 logic from the common concerns
      def include_params
        false
      end

      # Use the params[:parents] configured by the route to construct a permit
      # hash containing each ID passed from the parents of a nested resource.
      def permit_parent_ids
        params[:parents]&.each_with_object({}) do |parent, obj|
          reflection = resource.reflect_on_association(parent)
          # Do not allow reflections that aren't defined as a parent
          next if reflection.nil?

          obj[reflection.foreign_key] = UUIDConstraint.new
        end || {}
      end

      def permitted_params
        @permitted_params ||= begin
          action_params = self.class.__permitted_params_for_action.try(:[], action_name.to_sym) || {}
          parent_params = V2::ApplicationController.__permitted_params_for_action.try(:[], action_name.to_sym) || {}

          # Merge all permit hashes to a single one using reduce and allow them through
          params.permit([action_params, parent_params, permit_parent_ids, DEFAULT_PERMITTED].reduce(&:merge))
        end
      end
    end
  end
end
