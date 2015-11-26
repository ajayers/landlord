require 'active_support/deprecation'

module Landlord
  module Deprecation

    def self.warn(message)
      ActiveSupport::Deprecation.warn message
    end
  end
end
