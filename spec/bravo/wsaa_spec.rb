require 'spec_helper'

describe "Wssa" do
  before do
    @stub_now = Time.now
    Time.stub(:now).and_return(@stub_now)

    @now = Time.now
    Time.now.should == @now
    from = @now.strftime("%FT%T%:z")
    to   = ((@now - 120) + (24*60*60)).strftime("%FT%T%:z")
    id   = @now.strftime("%s")
    @tra  = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<loginTicketRequest version="1.0">
  <header>
    <uniqueId>#{ id }</uniqueId>
    <generationTime>#{ from }</generationTime>
    <expirationTime>#{ to }</expirationTime>
  </header>
  <service>wsfe</service>
</loginTicketRequest>
EOF
  end

  describe ".build_tra" do
    it "sets the body for the ticket request" do
      Bravo::Wsaa.build_tra.should == @tra
    end
  end

  describe ".build_cms" do
    it "returns the cms with the tra in it" do
      pending "find a proper way to stub openssl"
    end
  end

  describe ".login" do
    it "should work" do
      Bravo::Wsaa.login.should be_true
    end
  end
end