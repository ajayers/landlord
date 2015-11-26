require 'spec_helper'

describe 'query caching' do
  let(:db_names) { [db1, db2] }

  before do
    Landlord.configure do |config|
      config.tenant_names = lambda{ Company.pluck(:database) }
    end

    Landlord::Tenant.reload!(config)

    db_names.each do |db_name|
      Landlord::Tenant.create(db_name)
      Company.create database: db_name
    end
  end

  after do
    db_names.each{ |db| Landlord::Tenant.destroy(db) }
    Landlord::Tenant.reset
    Company.delete_all
  end

  it 'clears the ActiveRecord::QueryCache after switching databases' do
    db_names.each do |db_name|
      Landlord::Tenant.switch! db_name
      User.create! name: db_name
    end

    ActiveRecord::Base.connection.enable_query_cache!

    Landlord::Tenant.switch! db_names.first
    User.find_by_name(db_names.first).name.should == db_names.first

    Landlord::Tenant.switch! db_names.last
    User.find_by_name(db_names.first).should be_nil
  end
end
