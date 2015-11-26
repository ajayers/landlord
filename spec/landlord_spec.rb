require 'spec_helper'

describe Landlord do
  it "should be valid" do
    Landlord.should be_a(Module)
  end

  it "should be a valid app" do
    ::Rails.application.should be_a(Dummy::Application)
  end
end
