require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'AuthData' do
  describe '.fetch' do
    it 'creates constants for todays data' do
      Bravo.constants.should_not include(:TOKEN, :SIGN)

      Bravo::AuthData.fetch

      Bravo.constants.should include(:TOKEN, :SIGN)
    end
  end
end