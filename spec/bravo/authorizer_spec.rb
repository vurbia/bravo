require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Authorizer" do
  it "should read credentials on initialize" do
    authorizer = Bravo::Authorizer.new
    authorizer.pkey.should == 'spec/fixtures/pkey'
    authorizer.cert.should == 'spec/fixtures/cert.crt'
  end
end