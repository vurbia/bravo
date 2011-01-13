require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Biller" do
  it "should authorize basic bill" do
    bill = Bravo::Biller.new
    resp = bill.dummy

    res = resp[:fecae_solicitar_response][:fecae_solicitar_result]
    res[:fe_cab_resp][:resultado].should == "A"
    res[:fe_det_resp][:fecae_det_response][:resultado].should == "A"
  end
end