# You can have Landlord route to the appropriate Tenant by adding some Rack middleware.
# Landlord can support many different "Elevators" that can take care of this routing to your data.
# Require whichever Elevator you're using below or none if you have a custom one.
#
# require 'landlord/elevators/generic'
# require 'landlord/elevators/domain'
require 'landlord/elevators/subdomain'

#
# Landlord Configuration
#
Landlord.configure do |config|

  # In order to migrate all of your Tenants you need to provide a list of Tenant names to Landlord.
  # You can make this dynamic by providing a Proc object to be called on migrations.
  # This object should yield an array of strings representing each Tenant name.
  #
  # config.tenant_names = lambda{ Customer.pluck(:tenant_name) }
  # config.tenant_names = ['tenant1', 'tenant2']
  #
  config.tenant_names = lambda { ToDo_Tenant_Or_User_Model.pluck :database }

  # TODO AJA
  # There are cases where you might want some schemas to always be in your search_path
  # e.g when using a PostgreSQL extension like hstore.
  # Any schemas added here will be available along with your selected Tenant.
  #
  # config.persistent_schemas = %w{ hstore }

end

# Setup a custom Tenant switching middleware. The Proc should return the name of the Tenant that
# you want to switch to.
# Rails.application.config.middleware.use 'Landlord::Elevators::Generic', lambda { |request|
#   request.host.split('.').first
# }

# Rails.application.config.middleware.use 'Landlord::Elevators::Domain'
Rails.application.config.middleware.use 'Landlord::Elevators::Subdomain'
