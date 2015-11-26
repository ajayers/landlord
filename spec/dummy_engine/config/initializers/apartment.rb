# Require whichever elevator you're using below here...
#
# require 'landlord/elevators/generic'
# require 'landlord/elevators/domain'
require 'landlord/elevators/subdomain'

#
# Landlord Configuration
#
Landlord.configure do |config|

  # use raw SQL dumps for creating postgres schemas?
  #config.use_sql = true

  # configure persistent schemas (E.g. hstore )
  # config.persistent_schemas = %w{ hstore }

  # add the Rails environment to database names?
  # config.prepend_environment = true
  # config.append_environment = true

  # supply list of database names for migrations to run on
  # config.tenant_names = lambda{ ToDo_Tenant_Or_User_Model.pluck :database }

  # Specify a connection other than ActiveRecord::Base for landlord to use (only needed if your models are using a different connection)
  # config.connection_class = ActiveRecord::Base
end

##
# Elevator Configuration

# Rails.application.config.middleware.use 'Landlord::Elevators::Generic', lambda { |request|
#   # TODO: supply generic implementation
# }

# Rails.application.config.middleware.use 'Landlord::Elevators::Domain'

Rails.application.config.middleware.use 'Landlord::Elevators::Subdomain'
