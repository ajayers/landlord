# Landlord

*Multitenancy for Rails and ActiveRecord on PostgreSQL*

## Credit

This gem started from the [Apartment](https://github.com/influitive/apartment) gem. The original code was stripped down and refactored to focus solely on PostgreSQL and the use of ```search_path```.

## Installation

### Rails

Add the following to your Gemfile:

```ruby
gem 'landlord'
```

Then generate your `Landlord` config file using

```ruby
bundle exec rails generate landlord:install
```

This will create a `config/initializers/landlord.rb` initializer file.
Configure as needed using the docs below.

That's all you need to set up the Landlord libraries. If you want to switch tenants
on a per-user basis, look under "Usage - Switching tenants per request", below.

## Usage

### Creating new Tenants

Before you can switch to a new landlord tenant, you will need to create it. Whenever
you need to create a new tenant, you can run the following command:

```ruby
Landlord::Tenant.create('tenant_name')
```

### Switching Tenants

To switch tenants using Landlord, use the following command:

```ruby
Landlord::Tenant.switch!('tenant_name')
```

When switch is called, all requests coming to ActiveRecord will be routed to the tenant
you specify, with the exception of tables/models living in the global, i.e. public, schama.

### Switching Tenants per request

You can have Landlord route to the appropriate tenant by adding some Rack middleware.
Landlord can support many different "Elevators" that can take care of this routing to your data.

The initializer above will generate the appropriate code for the Subdomain elevator
by default. You can see this in `config/initializers/landlord.rb` after running
that generator. If you're *not* using the generator, you can specify your
elevator below. Note that in this case you will **need** to require the elevator
manually in your `application.rb` like so

```ruby
# config/application.rb
require 'landlord/elevators/subdomain' # or 'domain' or 'generic'
```

**Switch on subdomain**
In house, we use the subdomain elevator, which analyzes the subdomain of the request and switches to a tenant schema of the same name. It can be used like so:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    config.middleware.use 'Landlord::Elevators::Subdomain'
  end
end
```

If you want to exclude a domain, for example if you don't want your application to treate www like a subdomain, in an initializer in your application, you can set the following:

```ruby
# config/initializers/landlord/subdomain_exclusions.rb
Landlord::Elevators::Subdomain.excluded_subdomains = ['www']
```

This functions much in the same way as Landlord.excluded_models. This example will prevent switching your tenant when the subdomain is www. Handy for subdomains like: "public", "www", and "admin" :)

**Switch on domain**
To switch based on full domain (excluding subdomains *ie 'www'* and top level domains *ie '.com'* ) use the following:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    config.middleware.use 'Landlord::Elevators::Domain'
  end
end
```

**Switch on full host using a hash**
To switch based on full host with a hash to find corresponding tenant name use the following:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    config.middleware.use 'Landlord::Elevators::HostHash', {'example.com' => 'example_tenant'}
  end
end
```

**Custom Elevator**
A Generic Elevator exists that allows you to pass a `Proc` (or anything that responds to `call`) to the middleware. This Object will be passed in an `ActionDispatch::Request` object when called for you to do your magic. Landlord will use the return value of this proc to switch to the appropriate tenant.  Use like so:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    # Obviously not a contrived example
    config.middleware.use 'Landlord::Elevators::Generic', Proc.new { |request| request.host.reverse }
  end
end
```

Your other option is to subclass the Generic elevator and implement your own
switching mechanism. This is exactly how the other elevators work. Look at
the `subdomain.rb` elevator to get an idea of how this should work. Basically
all you need to do is subclass the generic elevator and implement your own
`parse_tenant_name` method that will ultimately return the name of the tenant
based on the request being made. It *could* look something like this:

```ruby
# app/middleware/my_custom_elevator.rb
class MyCustomElevator < Landlord::Elevators::Generic

  # @return {String} - The tenant to switch to
  def parse_tenant_name(request)
    # request is an instance of Rack::Request

    # example: look up some tenant from the db based on this request
    tenant_name = SomeModel.from_request(request)

    return tenant_name
  end
end
```

## Config

The following config options should be set up in a Rails initializer such as:

    config/initializers/landlord.rb

To set config options, add this to your initializer:

```ruby
Landlord.configure do |config|
  # set your options (described below) here
end
```

## Persistent Schemas
Landlord will normally just switch the `schema_search_path` whole hog to the one passed in.  This can lead to problems if you want other schemas to always be searched as well.  Enter `persistent_schemas`.  You can configure a list of other schemas that will always remain in the search path, while the default gets swapped out:

```ruby
config.persistent_schemas = ['some', 'other', 'schemas']
```

### Installing Extensions into Persistent Schemas
Persistent Schemas have numerous useful applications.  [Hstore](http://www.postgresql.org/docs/9.1/static/hstore.html), for instance, is a popular storage engine for Postgresql.  In order to use extensions such as Hstore, you have to install it to a specific schema and have that always in the `schema_search_path`.

When using extensions, keep in mind:
* Extensions can only be installed into one schema per database, so we will want to install it into a schema that is always available in the `schema_search_path`
* The schema and extension need to be created in the database *before* they are referenced in migrations, database.yml or landlord.
* There does not seem to be a way to create the schema and extension using standard rails migrations.
* Rails db:test:prepare deletes and recreates the database, so it needs to be easy for the extension schema to be recreated here.

#### 1. Ensure the extensions schema is created when the database is created

```ruby
# lib/tasks/db_enhancements.rake

####### Important information ####################
# This file is used to setup a shared extensions #
# within a dedicated schema. This gives us the   #
# advantage of only needing to enable extensions #
# in one place.                                  #
#                                                #
# This task should be run AFTER db:create but    #
# BEFORE db:migrate.                             #
##################################################


namespace :db do
  desc 'Also create shared_extensions Schema'
  task :extensions => :environment  do
    # Create Schema
    ActiveRecord::Base.connection.execute 'CREATE SCHEMA IF NOT EXISTS shared_extensions;'
    # Enable Hstore
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS HSTORE SCHEMA shared_extensions;'
    # Enable UUID-OSSP
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA shared_extensions;'
  end
end

Rake::Task["db:create"].enhance do
  Rake::Task["db:extensions"].invoke
end

Rake::Task["db:test:purge"].enhance do
  Rake::Task["db:extensions"].invoke
end
```

#### 2. Ensure the schema is in Rails' default connection

Next, your `database.yml` file must mimic what you've set for your default and persistent schemas in Landlord.  When you run migrations with Rails, it won't know about the extensions schema because Landlord isn't injected into the default connection, it's done on a per-request basis, therefore Rails doesn't know about `hstore` or `uuid-ossp` during migrations.  To do so, add the following to your `database.yml` for all environments

```yaml
# database.yml
...
adapter: postgresql
schema_search_path: "public,shared_extensions"
...
```

This would be for a config with `default_schema` set to `public` and `persistent_schemas` set to `['shared_extensions']`. **Note**: This only works on Heroku with [Rails 4.1+](https://devcenter.heroku.com/changelog-items/426). For apps that use older Rails versions hosted on Heroku, the only way to properly setup is to start with a fresh PostgreSQL instance:

1. Append `?schema_search_path=public,hstore` to your `DATABASE_URL` environment variable, by this you don't have to revise the `database.yml` file (which is impossible since Heroku regenerates a completely different and immutable `database.yml` of its own on each deploy)
2. Run `heroku pg:psql` from your command line
3. And then `DROP EXTENSION hstore;` (**Note:** This will drop all columns that use `hstore` type, so proceed with caution; only do this with a fresh PostgreSQL instance)
4. Next: `CREATE SCHEMA IF NOT EXISTS hstore;`
5. Finally: `CREATE EXTENSION IF NOT EXISTS hstore SCHEMA hstore;` and hit enter (`\q` to exit)

To double check, login to the console of your Heroku app and see if `Landlord.connection.schema_search_path` is `public,hstore`

#### 3. Ensure the schema is in the landlord config
```ruby
# config/initializers/landlord.rb
...
config.persistent_schemas = ['shared_extensions']
...
```

### Managing Migrations

In order to migrate all of your tenants (or postgresql schemas) you need to provide a list
of dbs to Landlord.  You can make this dynamic by providing a Proc object to be called on migrations.
This object should yield an array of string representing each tenant name.  Example:

```ruby
# Dynamically get tenant names to migrate
config.tenant_names = lambda{ Customer.pluck(:tenant_name) }

# Use a static list of tenant names for migrate
config.tenant_names = ['tenant1', 'tenant2']
```

You can then migrate your tenants using the normal rake task:

```ruby
rake db:migrate
```

This just invokes `Landlord::Tenant.migrate(#{tenant_name})` for each tenant name supplied
from `Landlord.tenant_names`

Note that you can disable the default migrating of all tenants with `db:migrate` by setting
`Landlord.db_migrate_tenants = false` in your `Rakefile`. Note this must be done
*before* the rake tasks are loaded. ie. before `YourApp::Application.load_tasks` is called

## Contributing

* In both `spec/dummy/config` and `spec/config`, you will see `database.yml.sample` files
  * Copy them into the same directory but with the name `database.yml`
  * Edit them to fit your own settings
* Rake tasks (see the Rakefile) will help you setup your dbs necessary to run tests
* Please issue pull requests to the `development` branch.  All development happens here, master is used for releases
* Ensure that your code is accompanied with tests.  No code will be merged without tests

* If you're looking to help, check out the TODO file for some upcoming changes I'd like to implement in Landlord.

## License

Landlord is released under the [MIT License](http://www.opensource.org/licenses/MIT).
