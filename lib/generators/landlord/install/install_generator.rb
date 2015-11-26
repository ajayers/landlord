module Landlord
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_files
      template "landlord.rb", File.join("config", "initializers", "landlord.rb")
    end

  end
end
