require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'AuthData' do
  describe '.fetch' do
    it 'creates constants for todays data' do
      expect(Bravo.constants).not_to include(:TOKEN, :SIGN)

      Bravo::AuthData.fetch

      expect(Bravo.constants).to include(:TOKEN, :SIGN)
    end
  end
end
