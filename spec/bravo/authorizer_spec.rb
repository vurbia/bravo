require 'spec_helper'

describe "Authorizer" do
  describe ".initialize" do
    #TODO: trivial test
    it "reads credentials on initialize" do
      authorizer = Bravo::Authorizer.new

      authorizer.pkey.should == Bravo.pkey
      authorizer.cert.should == Bravo.cert
    end
  end
end