# frozen_string_literal: true

module Decidim
  module Ideas
    # This is the engine that runs on the public interface of `decidim-ideas`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Ideas::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :ideas, only: [:show, :index, :new, :create, :edit, :update] do
          collection do
            post :update_category
            post :publish_answers
            post :update_area_scope
            resource :ideas_merge, only: [:create]
            resource :ideas_split, only: [:create]
            resource :valuation_assignment, only: [:create, :destroy]
          end
          resources :idea_answers, only: [:edit, :update]
          resources :idea_notes, only: [:create]
        end

        root to: "ideas#index"
      end

      initializer "decidim_ideas_admin.routes", before: :add_routing_paths do
        # Mount the extra admin routes to Decidim::Admin::Engine because
        # otherwise they get mounted under the component itself. We need these
        # specific routes at the admin level.
        Decidim::Admin::Engine.routes.prepend do
          resources :ideas_component_settings, only: [] do
            member do
              get :area_coordinates
            end
          end
        end
      end

      def load_seed
        nil
      end

      initializer "decidim_ideas_admin.overrides", after: "decidim.action_controller" do |app|
        app.config.to_prepare do
          # Required for the component settings customizations
          Decidim::Admin::ApplicationController.send(
            :helper,
            Decidim::Ideas::AreaScopesHelper
          )
          Decidim::Admin::SettingsHelper.include Decidim::Ideas::Admin::ComponentSettings
        end
      end
    end
  end
end
