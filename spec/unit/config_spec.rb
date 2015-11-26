require 'spec_helper'

describe Landlord do

  describe "#config" do

    let(:seed_data_file_path){ "#{Rails.root}/db/seeds/import.rb" }

    it "should yield the Landlord object" do
      Landlord.configure do |config|
        config.should == Landlord
      end
    end

    it "should set seed_data_file" do
      Landlord.configure do |config|
        config.seed_data_file = seed_data_file_path
      end
      Landlord.seed_data_file.should eq(seed_data_file_path)
    end

    it "should set seed_after_create" do
      Landlord.configure do |config|
        config.seed_after_create = true
      end
      Landlord.seed_after_create.should be true
    end

    it "should set tld_length" do
      Landlord.configure do |config|
        config.tld_length = 2
      end
      Landlord.tld_length.should == 2
    end

    context "databases" do
      it "should return object if it doesnt respond_to call" do
        tenant_names = ['users', 'companies']

        Landlord.configure do |config|
          config.tenant_names = tenant_names
        end
        Landlord.tenant_names.should == tenant_names
      end

      it "should invoke the proc if appropriate" do
        tenant_names = lambda{ ['users', 'users'] }
        tenant_names.should_receive(:call)

        Landlord.configure do |config|
          config.tenant_names = tenant_names
        end
        Landlord.tenant_names
      end

      it "should return the invoked proc if appropriate" do
        dbs = lambda{ Company.all }

        Landlord.configure do |config|
          config.tenant_names = dbs
        end

        Landlord.tenant_names.should == Company.all
      end
    end

  end
end
