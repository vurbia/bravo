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
      @bill.documento.should == Bravo.default_documento
      @bill.moneda.should == Bravo.default_moneda
    end

    it "should calculate it's cbte_tipo for Responsable Inscripto" do
      @bill.iva_cond = :responsable_inscripto
      @bill.cbte_type.should == "01"
    end

    it "should calculate it's cbte_tipo for Consumidor Final" do
      @bill.iva_cond = :consumidor_final
      @bill.cbte_type.should == "06"
    end

    it "raise error on nil iva cond" do
      @bill.iva_cond = 12
      expect{@bill.cbte_type}.to raise_error(Bravo::NullOrInvalidAttribute)
    end

    it "should fetch non Peso currency's exchange rate" do
      @bill.moneda = :dolar
      @bill.exchange_rate.to_i.should be > 0
    end

    it "should return 1 for Peso currency" do
      @bill.moneda = :peso
      @bill.exchange_rate.should == 1
    end

    it "should calculate the IVA array values" do
      @bill.iva_cond = :responsable_inscripto
      @bill.moneda = :peso
      @bill.net = 100.89
      @bill.aliciva_id = 2

      @bill.iva_sum.should be_within(0.05).of(21.18)
      @bill.total.should be_within(0.05).of(122.07)
    end

    it "should use give due date an service dates, or todays date" do
      @bill.net = 100
      @bill.aliciva_id = 2
      @bill.doc_num = "30710151543"
      @bill.iva_cond = :responsable_inscripto
      @bill.concepto = "Servicios"

      @bill.setup_bill

      detail = @bill.body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["FchServDesde"].should == Time.new.strftime('%Y%m%d')
      detail["FchServHasta"].should == Time.new.strftime('%Y%m%d')
      detail["FchVtoPago"].should   == Time.new.strftime('%Y%m%d')

      @bill.due_date       = Date.new(2011, 12, 10).strftime('%Y%m%d')
      @bill.fch_serv_desde = Date.new(2011, 11, 01).strftime('%Y%m%d')
      @bill.fch_serv_hasta = Date.new(2011, 11, 30).strftime('%Y%m%d')

      @bill.setup_bill

      detail = @bill.body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["FchServDesde"].should == "20111101"
      detail["FchServHasta"].should == "20111130"
      detail["FchVtoPago"].should   == "20111210"
    end

    it "should authorize a valid bill" do
      @bill.net = 100
      @bill.aliciva_id = 2
      @bill.doc_num = "30710151543"
      @bill.iva_cond = :responsable_inscripto
      @bill.concepto = "Servicios"

      pp @bill.authorize
    end
  end
end
