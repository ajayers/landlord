require 'spec_helper'
require 'landlord/migrator'

describe Landlord::Migrator do

  let(:tenant){ Landlord::Test.next_db }

  # Don't need a real switch here, just testing behaviour
  before { Landlord::Tenant.stub(:connect_to_new) }

  describe "::migrate" do
    it "switches and migrates" do
      expect(Landlord::Tenant).to receive(:switch).with(tenant).and_call_original
      expect(Landlord::Migrator).to receive(:create_tenant_schema_migrations_table)
      expect(ActiveRecord::Migrator).to receive(:migrate)

      Landlord::Migrator.migrate(tenant)
    end
  end

  describe "::run" do
    it "switches and runs" do
      expect(Landlord::Tenant).to receive(:switch).with(tenant).and_call_original
      #expect(Landlord::Migrator).to receive(:create_tenant_schema_migrations_table)
      expect(ActiveRecord::Migrator).to receive(:run).with(:up, anything, 1234)

      Landlord::Migrator.run(:up, tenant, 1234)
    end
  end

  describe "::rollback" do
    it "switches and rolls back" do
      expect(Landlord::Tenant).to receive(:switch).with(tenant).and_call_original
      #expect(Landlord::Migrator).to receive(:create_tenant_schema_migrations_table)
      expect(ActiveRecord::Migrator).to receive(:rollback).with(anything, 2)

      Landlord::Migrator.rollback(tenant, 2)
    end
  end
end
