module Landlord
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_initializer
      template "landlord.rb", File.join("config", "initializers", "landlord.rb")
    end

    def create_directory
      empty_directory File.join("db", "landlord", "migrate")
    end

    def copy_seeds
      template "seeds.rb", File.join("db", "landlord", "seeds.rb")
    end
  end
end
