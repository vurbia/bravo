require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bill" do
  it "should setup a header hash" do
    @header = Bravo::Bill.header(0)
    @header.size.should == 3
    ["CantReg", "CbteTipo", "PtoVta"].each do |key|
      @header.has_key?(key).should == true
    end
  end

  describe "instance" do
    before(:each) {@bill = Bravo::Bill.new}

    it "should initialize according to Bravo defaults" do
      @bill.client.class.name.should == "Savon::Client"
      ["Token", "Sign", "Cuit"].each do |key|
        @bill.body["Auth"][key].should_not == nil
      end
      @bill.doc_type.should == Bravo.default_doc_type
      @bill.mon_id.should == Bravo.default_mon_id
    end

    it "should calculate it's cbte_tipo for Responsable Inscripto" do
      @bill.iva_cond = 0
      @bill.cbte_type.should == "01"
    end

    it "should calculate it's cbte_tipo for Consumidor Final" do
      @bill.iva_cond = 1
      @bill.cbte_type.should == "06"
    end

    it "raise error on nil iva cond" do
      @bill.iva_cond = 12
      expect{@bill.cbte_type}.to raise_error(Bravo::NullOrInvalidAttribute)
    end

    it "should fetch non Peso currency's exchange rate" do
      @bill.mon_id = 1
      p @bill.exchange_rate
      @bill.exchange_rate.to_i.should be > 0
    end

    it "should return 1 for Peso currency" do
      @bill.mon_id = 0
      @bill.exchange_rate.should == 1
    end

    it "should calculate the IVA array values" do
      @bill.iva_cond = 0
      @bill.mon_id = 0
      @bill.net = 100.89
      @bill.aliciva_id = 2

      @bill.iva_sum.should == 21
      @bill.total.should == 121
    end

    it "should authorize a valid bill" do
      @bill.net = 100
      @bill.aliciva_id = 2
      @bill.doc_num = "30710151543"
      @bill.iva_cond = 0
      @bill.concept = 1

      pp @bill.authorize
    end
  end
end