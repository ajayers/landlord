require 'spec_helper'
require 'rake'
require 'landlord/migrator'

describe "landlord rake tasks" do

  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    load 'tasks/landlord.rake'
    # stub out rails tasks
    Rake::Task.define_task('db:migrate')
    Rake::Task.define_task('db:seed')
    Rake::Task.define_task('db:rollback')
    Rake::Task.define_task('db:migrate:up')
    Rake::Task.define_task('db:migrate:down')
    Rake::Task.define_task('db:migrate:redo')
  end

  after do
    Rake.application = nil
    ENV['VERSION'] = nil    # linux users reported env variable carrying on between tests
  end

  after(:all) do
    Landlord::Test.load_schema
  end

  let(:version){ '1234' }

  context 'database migration' do

    let(:tenant_names){ 3.times.map{ Landlord::Test.next_db } }
    let(:tenant_count){ tenant_names.length }

    before do
      Landlord.stub(:tenant_names).and_return tenant_names
    end

    describe "landlord:migrate" do
      it "should migrate tenant dbs" do
        Landlord::Migrator.should_receive(:migrate).exactly(tenant_count).times

        # XXX AJA: the next line prevents and dumping of the schema. ideally it would 
        #   be something like the two lines below. need to refactor.
        # require 'landlord/schema_dumper'
        # Landlord::SchemaDumper.should_receive(:dump).exactly(1).times
        File.should_receive(:open).exactly(1).times

        @rake['landlord:migrate'].invoke
      end
    end

    describe "landlord:migrate:up" do

      context "without a version" do
        before do
          ENV['VERSION'] = nil
        end

        it "requires a version to migrate to" do
          lambda{
            @rake['landlord:migrate:up'].invoke
          }.should raise_error("VERSION is required")
        end
      end

      context "with version" do

        before do
          ENV['VERSION'] = version
        end

        it "migrates up to a specific version" do
          Landlord::Migrator.should_receive(:run).with(:up, anything, version.to_i).exactly(tenant_count).times
          @rake['landlord:migrate:up'].invoke
        end
      end
    end

    describe "landlord:migrate:down" do

      context "without a version" do
        before do
          ENV['VERSION'] = nil
        end

        it "requires a version to migrate to" do
          lambda{
            @rake['landlord:migrate:down'].invoke
          }.should raise_error("VERSION is required")
        end
      end

      context "with version" do

        before do
          ENV['VERSION'] = version
        end

        it "migrates up to a specific version" do
          Landlord::Migrator.should_receive(:run).with(:down, anything, version.to_i).exactly(tenant_count).times
          @rake['landlord:migrate:down'].invoke
        end
      end
    end

    describe "landlord:rollback" do
      let(:step){ '3' }

      it "should rollback dbs" do
        Landlord::Migrator.should_receive(:rollback).exactly(tenant_count).times
        @rake['landlord:rollback'].invoke
      end

      it "should rollback dbs STEP amt" do
        Landlord::Migrator.should_receive(:rollback).with(anything, step.to_i).exactly(tenant_count).times
        ENV['STEP'] = step
        @rake['landlord:rollback'].invoke
      end
    end
  end
end
