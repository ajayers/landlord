require 'landlord/tenant'
require 'landlord/migrator'

landlord_namespace = namespace :landlord do

  desc "Create all tenants"
  task create: 'db:migrate' do
    tenants.each do |tenant|
      begin
        puts("Creating #{tenant} tenant")
        # quietly { Landlord::Tenant.create(tenant) }
        Landlord::Tenant.create(tenant) 
      rescue Landlord::TenantExists => e
        puts e.message
      end
    end
  end

  desc "Migrate all tenants"
  task :migrate do
    warn_if_tenants_empty

    tenants.each do |tenant|
      begin
        puts("Migrating #{tenant} tenant")
        Landlord::Migrator.migrate tenant
      rescue Landlord::TenantNotFound => e
        puts e.message
      end
    end

    if Landlord.tenant_names && t = Landlord.tenant_names[0]
      Landlord.connection.execute(%{set search_path = "#{t}"})
      Rake::Task["landlord:schema:dump"].invoke
      Landlord::Tenant.reset
    end
  end

  desc "Seed all tenants"
  task :seed do
    warn_if_tenants_empty

    tenants.each do |tenant|
      begin
        puts("Seeding #{tenant} tenant")
        Landlord::Tenant.switch(tenant) do
          Landlord::Tenant.seed
        end
      rescue Landlord::TenantNotFound => e
        puts e.message
      end
    end
  end

  desc "Rolls the migration back to the previous version (specify steps w/ STEP=n) across all tenants."
  task :rollback do
    warn_if_tenants_empty

    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    tenants.each do |tenant|
      begin
        puts("Rolling back #{tenant} tenant")
        Landlord::Migrator.rollback tenant, step
      rescue Landlord::TenantNotFound => e
        puts e.message
      end
    end
  end

  namespace :migrate do
    desc 'Runs the "up" for a given migration VERSION across all tenants.'
    task :up do
      warn_if_tenants_empty

      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      tenants.each do |tenant|
        begin
          puts("Migrating #{tenant} tenant up")
          Landlord::Migrator.run :up, tenant, version
        rescue Landlord::TenantNotFound => e
          puts e.message
        end
      end
    end

    desc 'Runs the "down" for a given migration VERSION across all tenants.'
    task :down do
      warn_if_tenants_empty

      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      tenants.each do |tenant|
        begin
          puts("Migrating #{tenant} tenant down")
          Landlord::Migrator.run :down, tenant, version
        rescue Landlord::TenantNotFound => e
          puts e.message
        end
      end
    end

    desc  'Rolls back the tenant one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo do
      if ENV['VERSION']
        landlord_namespace['migrate:down'].invoke
        landlord_namespace['migrate:up'].invoke
      else
        landlord_namespace['rollback'].invoke
        landlord_namespace['migrate'].invoke
      end
    end
  end

  task :load_config do
    ActiveRecord::Base.configurations       = ActiveRecord::Tasks::DatabaseTasks.database_configuration || {}
    ActiveRecord::Migrator.migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths
  end

  namespace :schema do
    desc 'Create a db/landlord/schema.rb file that is portable against any DB supported by AR'
    task :dump => [:load_config] do
      require 'landlord/schema_dumper'
      filename = ENV['LANDLORD_SCHEMA'] || File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'landlord', 'schema.rb')
      File.open(filename, "w:utf-8") do |file|
        Landlord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
      landlord_namespace['schema:dump'].reenable
    end
  end

  def tenants
    ENV['DB'] ? ENV['DB'].split(',').map { |s| s.strip } : Landlord.tenant_names || []
  end

  def warn_if_tenants_empty
    if tenants.empty?
      puts <<-WARNING
        [WARNING] - The list of tenants to migrate appears to be empty. This could mean a few things:

          1. You may not have created any, in which case you can ignore this message
          2. You've run `landlord:migrate` directly without loading the Rails environment
            * `landlord:migrate` is now deprecated. Tenants will automatically be migrated with `db:migrate`

        Note that your tenants currently haven't been migrated. You'll need to run `db:migrate` to rectify this.
      WARNING
    end
  end
end
