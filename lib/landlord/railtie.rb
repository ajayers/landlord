require 'rails'
require 'landlord/tenant'

module Landlord
  class Railtie < Rails::Railtie

    #
    #   Set up our default config options
    #   Do this before the app initializers run so we don't override custom settings
    #
    config.before_initialize do
      Landlord.configure do |config|
        config.tenant_names = []
        config.seed_after_create = false
        config.tld_length = 1
      end

      ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
    end

    #   Hook into ActionDispatch::Reloader to ensure Landlord is properly initialized
    #
    config.to_prepare do
      Landlord::Tenant.init unless ARGV.include? 'assets:precompile'
    end

    #
    #   Ensure rake tasks are loaded
    #
    rake_tasks do
      load 'tasks/landlord.rake'
      require 'landlord/tasks/enhancements' if Landlord.db_migrate_tenants
    end

  end
end
