module Landlord
  module Spec
    module Setup

      def self.included(base)
        base.instance_eval do
          let(:db1){ Landlord::Test.next_db }
          let(:db2){ Landlord::Test.next_db }
          let(:connection){ ActiveRecord::Base.connection }

          # This around ensures that we run these hooks before and after
          # any before/after hooks defined in individual tests
          # Otherwise these actually get run after test defined hooks
          around(:each) do |example|

            def config
              db = example.metadata.fetch(:database, :postgresql)

              Landlord::Test.config['connections'][db.to_s].symbolize_keys
            end

            # before
            Landlord::Tenant.reload!(config)
            ActiveRecord::Base.establish_connection config

            example.run

            # after
            Rails.configuration.database_configuration = {}
            ActiveRecord::Base.clear_all_connections!

            Landlord.reset
            Landlord::Tenant.reload!
          end
        end
      end
    end
  end
end
