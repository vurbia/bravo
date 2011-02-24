require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "AuthData" do
  it "should create constants for todays data" do
    Bravo::AuthData.fetch
    if RUBY_VERSION >= "1.9"
      Bravo.constants.should include(:TOKEN, :SIGN)
    else
      Bravo.constants.should include("TOKEN", "SIGN")
    end
  end
end
