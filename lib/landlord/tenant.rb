require 'forwardable'
require 'landlord/deprecation'

module Landlord
  module Tenant

    extend self
    extend Forwardable

    attr_writer :config

    def init
    end

    def reload!(config = nil)
      @config = config
    end

    def create(tenant)
      create_schema(tenant)
      create_schema_migrations_table(tenant)

      if File.exists?(Landlord.database_schema_file)
        focus(tenant) { load(Landlord.database_schema_file) }
      end

      switch(tenant) do
        seed_data if Landlord.seed_after_create
        yield if block_given?
      end
    end

    def current
      @current
    end

    def each(tenants = Landlord.tenant_names)
      tenants.each do |tenant|
        switch(tenant) { yield tenant }
      end
    end

    def reset
      @current = nil
      Landlord.connection.schema_search_path = full_search_path
    end

    def destroy(tenant)
      Landlord.connection.execute(%{DROP SCHEMA "#{tenant}" CASCADE})

    rescue *rescuable_exceptions
      raise TenantNotFound, "The tenant #{tenant} cannot be found"
    end

    def switch!(tenant = nil)
      return reset if tenant.nil?

      connect_to_new(tenant).tap do
        Landlord.connection.clear_query_cache
      end
    end

    def switch(tenant = nil)
      if block_given?
        begin
          previous_tenant = current
          switch!(tenant)
          yield

        ensure
          switch!(previous_tenant) rescue reset
        end
      else
        Landlord::Deprecation.warn("[Deprecation Warning] `switch` now requires a block reset to the default tenant after the block. Please use `switch!` instead if you don't want this")
        switch!(tenant)
      end
    end

    def seed_data
      # Don't log the output of seeding the db
      silence_stream(STDOUT){ load_or_warn(Landlord.seed_data_file) } if Landlord.seed_data_file
    end

    protected

      def create_schema(tenant)
        Landlord.connection.execute(%{CREATE SCHEMA "#{tenant}"})

      rescue *rescuable_exceptions
        raise TenantExists, "The schema #{tenant} already exists."
      end

      def create_schema_migrations_table(tenant)
	      table_name = "#{tenant}.#{ActiveRecord::SchemaMigration.table_name}"
	      index_name = "#{tenant}.#{ActiveRecord::SchemaMigration.index_name}"
	      unless Landlord.connection.table_exists?(table_name)
          version_options = {null: false}

          Landlord.connection.create_table(table_name, id: false) do |t|
            t.column :version, :string, version_options
          end
          Landlord.connection.add_index table_name, :version, unique: true, name: index_name
	      end
      end

      def connect_to_new(tenant = nil)
        return reset if tenant.nil?
        raise ActiveRecord::StatementInvalid.new("Could not find schema #{tenant}") unless Landlord.connection.schema_exists? tenant

        @current = tenant.to_s
        Landlord.connection.schema_search_path = full_search_path

      rescue *rescuable_exceptions
        raise TenantNotFound, "One of the following schema(s) is invalid: \"#{tenant}\" #{full_search_path}"
      end

      def focus(tenant)
        # FIXME AJA: raise exception if no block?
        if block_given?
          orig_search_path = Landlord.connection.schema_search_path
          begin
            Landlord.connection.schema_search_path = tenant
            yield
          ensure
            Landlord.connection.schema_search_path = orig_search_path
          end
        end
      end

    private

      def config
        @config ||= Landlord.connection_config
      end

      def full_search_path
        persistent_schemas.map(&:inspect).uniq.join(", ")
      end

      def persistent_schemas
        [@current, Landlord.persistent_schemas, 'public'].compact.flatten
      end

      def load_or_warn(file)
        if File.exists?(file)
          load(file)
        else
          puts %{#{file} doesn't exist yet}
        end
      end

      def rescuable_exceptions
        [ActiveRecord::ActiveRecordError] + Array(rescue_from)
      end

      def rescue_from
        []
      end
  end

end
