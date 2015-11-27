require 'landlord/tenant'

module Landlord
  module Migrator

    extend self

    def migrations_paths
      [Rails.root.join('db', 'landlord', 'migrate')]
    end

    def create_tenant_schema_migrations_table(database)
      table_name = "#{database}.#{ActiveRecord::SchemaMigration.table_name}"
      index_name = "#{database}.#{ActiveRecord::SchemaMigration.index_name}"
      unless ActiveRecord::Base.connection.table_exists?(table_name)
        version_options = {null: false}

        ActiveRecord::Base.connection.create_table(table_name, id: false) do |t|
          t.column :version, :string, version_options
        end
        ActiveRecord::Base.connection.add_index table_name, :version, unique: true, name: index_name
      end
    end

    # Migrate to latest
    def migrate(database)
      Tenant.switch(database) do
        create_tenant_schema_migrations_table(database)

        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        ActiveRecord::Migrator.migrate(migrations_paths, version) do |migration|
           ActiveRecord::Base.connection.clear_query_cache

          ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
        end
      end
    end

    # Migrate up/down to a specific version
    def run(direction, database, version)
      Tenant.switch(database) do
        ActiveRecord::Migrator.run(direction, ActiveRecord::Migrator.migrations_paths, version)
      end
    end

    # rollback latest migration `step` number of times
    def rollback(database, step = 1)
      Tenant.switch(database) do
        ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, step)
      end
    end
  end
end
