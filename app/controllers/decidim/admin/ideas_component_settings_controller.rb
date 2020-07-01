# frozen_string_literal: true

module Decidim
  module Admin
    # This controller adds extra functionality to the component settings view
    # of the ideas component.
    class IdeasComponentSettingsController < ::Decidim::Admin::ApplicationController
      include Decidim::Ideas::AreaScopesHelper

      helper_method :current_participatory_space

      def area_coordinates
        enforce_permission_to :create, :component
        raise ActionController::RoutingError, "Not found" unless scope_parent

        setting_name = params[:setting_name]
        manifest = Decidim.find_component_manifest("ideas")
        settings_manifest = manifest.settings(:global).attributes[setting_name.to_sym]
        raise ActionController::RoutingError, "Not found" unless settings_manifest
        raise ActionController::RoutingError, "Not found" if settings_manifest.type != :idea_area_scope_coordinates

        value = begin
          if component
            area_scopes_coordinates(component)
          else
            {}
          end
        end

        render(
          partial: "decidim/ideas/admin/shared/area_scope_coordinates",
          locals: {
            input_name_prefix: "component[settings][#{setting_name}]",
            value: value,
            parent: scope_parent
          }
        )
      end

      private

      def component_manifest
        @component_manifest ||= Decidim.find_component_manifest("ideas")
      end

      def component
        @component ||= begin
          comp = Decidim::Component.find_by(id: params[:id])
          if comp && comp.organization == current_organization
            comp
          else
            nil
          end
        end
      end

      def settings_manifest
        @settings_manifest ||= begin
          setting_name = params[:setting_name]
          settings_manifest = component_manifest.settings(:global).attributes[setting_name.to_sym]
        end
      end

      def scope_parent
        @scope_parent ||= begin
          scope = Decidim::Scope.find_by(id: params[:parent_scope_id])
          if scope && scope.organization == current_organization
            scope
          else
            nil
          end
        end
      end
    end
  end
end
