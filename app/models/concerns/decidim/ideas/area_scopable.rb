# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Ideas
    # A concern for connecting ideas to area scopes.
    module AreaScopable
      extend ActiveSupport::Concern

      included do
        belongs_to :area_scope,
                  foreign_key: "area_scope_id",
                  class_name: "Decidim::Scope",
                  optional: true

        delegate :area_scopes, to: :organization

        validate :area_scope_belongs_to_organization
      end

      # Gets the children scopes of the object's scope.
      #
      # If it's global, returns the organization's top scopes.
      #
      # Returns an ActiveRecord::Relation.
      def area_subscopes
        area_scope ? area_scope.children : organization.top_scopes
      end

      # Whether the resource has subscopes or not.
      #
      # Returns a boolean.
      def has_area_subscopes?
        area_subscopes.any?
      end

      # Whether the passed subscope is out of the resource's scope.
      #
      # Returns a boolean
      def out_of_area_scope?(subscope)
        area_scope && !area_scope.ancestor_of?(subscope)
      end

      # If any, gets the previous scope of the object.
      #
      #
      # Returns a Decidim::Scope
      def previous_area_scope
        return if versions.count <= 1

        Decidim::Scope.find_by(id: versions.last.reify.area_scope_id)
      end

      private

      def area_scope_belongs_to_organization
        return if !area_scope || !organization

        errors.add(:area_scope, :invalid) unless organization.scopes.where(id: area_scope.id).exists?
      end
    end
  end
end
