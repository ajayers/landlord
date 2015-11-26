Landlord.configure do |config|
  config.tenant_names = lambda{ Company.pluck(:database) }
end
