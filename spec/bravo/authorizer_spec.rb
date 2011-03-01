require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Authorizer" do
  it "should read credentials on initialize" do
    authorizer = Bravo::Authorizer.new
    authorizer.pkey.should == File.read('spec/fixtures/pkey')
    authorizer.cert.should == File.read('spec/fixtures/cert.crt')
  end

  it "should store sign and key for the day"
  it "should return sign and key for the day"
end