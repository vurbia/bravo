require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "AuthData" do
  it "should read todays data" do
    Bravo::AuthData.new.read
  end
  it "should get sign and key for the day"
  it "should get todays data and store it to file"
end