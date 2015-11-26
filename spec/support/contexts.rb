#   Some shared contexts for specs

shared_context "with default schema", :default_schema => true do
  let(:default_schema){ Landlord::Test.next_db }

  before do
    Landlord::Test.create_schema(default_schema)
    Landlord.default_schema = default_schema
  end

  after do
    # resetting default_schema so we can drop and any further resets won't try to access droppped schema
    Landlord.default_schema = nil
    Landlord::Test.drop_schema(default_schema)
  end
end

# Some default setup for elevator specs
shared_context "elevators", elevator: true do
  let(:company1)  { mock_model(Company, database: db1).as_null_object }
  let(:company2)  { mock_model(Company, database: db2).as_null_object }

  let(:api)       { Landlord::Tenant }

  before do
    Landlord.reset # reset all config
    Landlord.seed_after_create = false
    api.reload!(config)
    api.create(db1)
    api.create(db2)
  end

  after do
    api.drop(db1)
    api.drop(db2)
  end
end

shared_context "persistent_schemas", :persistent_schemas => true do
  let(:persistent_schemas){ ['hstore', 'postgis'] }

  before do
    persistent_schemas.map{|schema| subject.create(schema) }
    Landlord.persistent_schemas = persistent_schemas
  end

  after do
    Landlord.persistent_schemas = []
    persistent_schemas.map{|schema| subject.drop(schema) }
  end
end
