require 'spec_helper'
require 'landlord/elevators/host_hash'

describe Landlord::Elevators::HostHash do

  subject(:elevator){ Landlord::Elevators::HostHash.new(Proc.new{}, 'example.com' => 'example_tenant') }

  describe "#parse_tenant_name" do
    it "parses the host for a domain name" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'example.com')
      elevator.parse_tenant_name(request).should == 'example_tenant'
    end

    it "raises TenantNotFound exception if there is no host" do
      request = ActionDispatch::Request.new('HTTP_HOST' => '')
      expect { elevator.parse_tenant_name(request) }.to raise_error(Landlord::TenantNotFound)
    end

    it "raises TenantNotFound exception if there is no database associated to current host" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'example2.com')
      expect { elevator.parse_tenant_name(request) }.to raise_error(Landlord::TenantNotFound)
    end
  end

  describe "#call" do
    it "switches to the proper tenant" do
      Landlord::Tenant.should_receive(:switch!).with('example_tenant')

      elevator.call('HTTP_HOST' => 'example.com')
    end
  end
end
