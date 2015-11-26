require 'spec_helper'
require 'rake'

describe "landlord rake tasks", database: :postgresql do

  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Dummy::Application.load_tasks

    # rails tasks running F up the schema...
    Rake::Task.define_task('db:migrate')
    Rake::Task.define_task('db:seed')
    Rake::Task.define_task('db:rollback')
    Rake::Task.define_task('db:migrate:up')
    Rake::Task.define_task('db:migrate:down')
    Rake::Task.define_task('db:migrate:redo')

    Landlord.configure do |config|
      config.tenant_names = lambda{ Company.pluck(:database) }
    end
    Landlord::Tenant.reload!(config)

    # fix up table name of shared/excluded models
    Company.table_name = 'public.companies'
  end

  after { Rake.application = nil }

  context "with x number of databases" do

    let(:x){ 1 + rand(5) }    # random number of dbs to create
    let(:db_names){ x.times.map{ Landlord::Test.next_db } }
    let!(:company_count){ Company.count + db_names.length }

    before do
      db_names.collect do |db_name|
        Landlord::Tenant.create(db_name)
        Company.create :database => db_name
      end
    end

    after do
      db_names.each{ |db| Landlord::Tenant.destroy(db) }
      Company.delete_all
    end

    describe "#migrate" do
      it "should migrate all databases" do
        ActiveRecord::Migrator.should_receive(:migrate).exactly(company_count).times

        @rake['landlord:migrate'].invoke
      end
    end

    describe "#rollback" do
      it "should rollback all dbs" do
        ActiveRecord::Migrator.should_receive(:rollback).exactly(company_count).times

        @rake['landlord:rollback'].invoke
      end
    end

    describe "landlord:seed" do
      it "should seed all databases" do
        Landlord::Tenant.should_receive(:seed).exactly(company_count).times

        @rake['landlord:seed'].invoke
      end
    end
  end
end
