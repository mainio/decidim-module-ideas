# frozen_string_literal: true

class MigrateIdeaVersionsObjectChangesToJsonb < ActiveRecord::Migration[6.1]
  def up
    rename_column :decidim_ideas_idea_versions, :object_changes, :old_object_changes
    add_column :decidim_ideas_idea_versions, :object_changes, :jsonb
    Decidim::Ideas::IdeaVersion.reset_column_information
    Decidim::Ideas::IdeaVersion.where.not(old_object_changes: nil).find_each do |version|
      object_changes = ActiveSupport::HashWithIndifferentAccess.new(YAML.unsafe_load(version.old_object_changes))
      version.update_columns(old_object_changes: nil, object_changes:) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end