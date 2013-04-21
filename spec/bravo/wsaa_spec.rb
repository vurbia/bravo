require 'spec_helper'

describe 'Wsaa' do
  before do
    @now = (Time.now) - 120
    @from = @now.strftime('%FT%T%:z')
    @to   = (@now + ((12*60*60))).strftime('%FT%T%:z')
    @id   = @now.strftime('%s')
    @tra  = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<loginTicketRequest version="1.0">
  <header>
    <uniqueId>#{ @id }</uniqueId>
    <generationTime>#{ @from }</generationTime>
    <expirationTime>#{ @to }</expirationTime>
  </header>
  <service>wsfe</service>
</loginTicketRequest>
EOF
  end

  describe '.build_tra' do
    it 'sets the body for the ticket request' do
      Bravo::Wsaa.build_tra.should == @tra
    end
  end

  describe '.build_cms' do
    it 'returns the cms with the tra in it' do
      pending 'find a proper way to stub openssl'
    end
  end

  describe '.login' do
    use_vcr_cassette "login"
    xit 'should work' do
      Bravo::Wsaa.login.should be_true
    end
  end
end