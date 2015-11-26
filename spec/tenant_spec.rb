require 'spec_helper'

describe Landlord::Tenant do
  context "using postgresql", database: :postgresql do
    before do
      subject.reload!(config)
    end

    # TODO above spec are also with use_schemas=true
    context "with schemas" do
      before do
        Landlord.configure do |config|
          config.seed_after_create = true
        end
        subject.create db1
      end

      after{ subject.destroy db1 }

      describe "#create" do
        it "should seed data" do
          subject.switch! db1
          User.count.should be > 0
        end
      end

      describe "#switch!" do

        let(:x){ rand(3) }

        context "creating models" do

          before{ subject.create db2 }
          after{ subject.destroy db2 }

          it "should create a model instance in the current schema" do
            subject.switch! db2
            db2_count = User.count + x.times{ User.create }

            subject.switch! db1
            db_count = User.count + x.times{ User.create }

            subject.switch! db2
            User.count.should == db2_count

            subject.switch! db1
            User.count.should == db_count
          end
        end

      end
    end

    context "seed paths" do
      before do
        Landlord.configure do |config|
          config.seed_after_create = true
        end
      end

      after{ subject.destroy db1 }

      it 'should seed from default path' do
        subject.create db1
        subject.switch! db1
        User.count.should eq(3)
        User.first.name.should eq('Some User 0')
      end

      it 'should seed from custom path' do
        Landlord.configure do |config|
          config.seed_data_file = "#{Rails.root}/db/import.rb"
        end
        subject.create db1
        subject.switch! db1
        User.count.should eq(6)
        User.first.name.should eq('Different User 0')
      end
    end
  end
end
