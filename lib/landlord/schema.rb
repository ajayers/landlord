module Landlord
  class Schema < ActiveRecord::Schema

    # Returns the migrations paths for tenants
    #
    #   ActiveRecord::Schema.new.migrations_paths
    #   # => ["db/migrate"] # Rails migration path by default.
    def migrations_paths
      ActiveRecord::Migrator.migrations_paths.collect {|p| "#{p}_landlord"}
    end

  end
end
