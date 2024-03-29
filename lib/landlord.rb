require 'landlord/railtie' if defined?(Rails)
require 'active_support/core_ext/object/blank'
require 'forwardable'
require 'active_record'
require 'landlord/tenant'
require 'landlord/deprecation'

module Landlord

  class << self

    extend Forwardable

    ACCESSOR_METHODS  = [:use_sql, :seed_after_create, :prepend_environment, :append_environment]
    WRITER_METHODS    = [:tenant_names, :database_schema_file, :persistent_schemas, :connection_class, :tld_length, :db_migrate_tenants, :seed_data_file]

    attr_accessor(*ACCESSOR_METHODS)
    attr_writer(*WRITER_METHODS)

    def_delegators :connection_class, :connection, :connection_config, :establish_connection

    # configure landlord with available options
    def configure
      yield self if block_given?
    end

    # Be careful not to use `return` here so both Proc and lambda can be used without breaking
    def tenant_names
      @tenant_names.respond_to?(:call) ? @tenant_names.call : @tenant_names
    end

    # Whether or not db:migrate should also migrate tenants
    # defaults to true
    def db_migrate_tenants
      return @db_migrate_tenants if defined?(@db_migrate_tenants)

      @db_migrate_tenants = true
    end

    def persistent_schemas
      @persistent_schemas || []
    end

    def connection_class
      @connection_class || ActiveRecord::Base
    end

    def database_schema_file
      return @database_schema_file if defined?(@database_schema_file)

      @database_schema_file = Rails.root.join('db', 'landlord', 'schema.rb')
    end

    def seed_data_file
      return @seed_data_file if defined?(@seed_data_file)

      @seed_data_file = "#{Rails.root}/db/landlord/seeds.rb"
    end

    def tld_length
      @tld_length || 1
    end

    # Reset all the config for Landlord
    def reset
      (ACCESSOR_METHODS + WRITER_METHODS).each{|method| remove_instance_variable(:"@#{method}") if instance_variable_defined?(:"@#{method}") }
    end

  end

  # Exceptions
  LandlordError = Class.new(StandardError)

  # Tenant specified is unknown
  TenantNotFound = Class.new(LandlordError)

  # The Tenant attempting to be created already exists
  TenantExists = Class.new(LandlordError)
end
