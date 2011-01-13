require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "AuthData" do
  it "should create constants for todays data" do
    Bravo::AuthData.fetch
    Bravo.constants.should include("TOKEN", "SIGN")
  end
end