module Landlord
  class Schema < ActiveRecord::Schema

    # Returns the migrations paths for tenants
    #
    #   ActiveRecord::Schema.new.migrations_paths
    #   # => ["db/landlord/migrate"] # Rails migration path by default.
    def migrations_paths
      Landlord::Migrator.migrations_paths
    end

  end
end
