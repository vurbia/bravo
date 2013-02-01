require 'spec_helper'

describe "Bill" do
  let(:bill) { @bill = Bravo::Bill.new }

  describe ".header" do
    it "sets up a header hash" do
      @header = Bravo::Bill.header(0)
      @header.size.should == 3
      ["CantReg", "CbteTipo", "PtoVta"].each do |key|
        @header.has_key?(key).should == true
      end
    end
  end

  describe ".initialize" do
    it "applies Bravo's defaults" do
      bill.client.class.name.should == "Savon::Client"

      ["Token", "Sign", "Cuit"].each do |key|
        bill.body["Auth"][key].should_not == nil
      end

      bill.documento.should == Bravo.default_documento
      bill.moneda.should == Bravo.default_moneda
    end
  end

  describe "#cbte_type" do
    it "returns the bill type for Responsable Inscripto" do
      bill.iva_cond = :responsable_inscripto
      bill.cbte_type.should == "01"
    end

    it "returns the bill type for Consumidor Final" do
      bill.iva_cond = :consumidor_final
      bill.cbte_type.should == "06"
    end

    it "raises error on nil iva cond" do
      bill.iva_cond = 12

      expect{bill.cbte_type}.to raise_error(Bravo::NullOrInvalidAttribute)
    end
  end

  describe "#exchange_rate" do
    it "fetches non Peso currency's exchange rate" do
      bill.moneda = :dolar
      bill.exchange_rate.to_i.should be > 0
    end

    it "returns 1 for Peso currency" do
      bill.moneda = :peso
      bill.exchange_rate.should == 1
    end
  end

  describe "#iva_sum and #total" do
    it "calculate the IVA array values" do
      bill.iva_cond = :responsable_inscripto
      bill.moneda = :peso
      bill.net = 100.89
      bill.aliciva_id = 2

      bill.iva_sum.should be_within(0.05).of(21.18)
      bill.total.should be_within(0.05).of(122.07)
    end
  end

  describe "#setup_bill" do
    before do
      bill.net = 100
      bill.aliciva_id = 2
      bill.doc_num = "30710151543"
      bill.iva_cond = :responsable_inscripto
      bill.concepto = "Servicios"
    end

    it "uses today dates when due and service dates are ommitted" do
      bill.setup_bill

      detail = bill.body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["FchServDesde"].should == Time.new.strftime('%Y%m%d')
      detail["FchServHasta"].should == Time.new.strftime('%Y%m%d')
      detail["FchVtoPago"].should   == Time.new.strftime('%Y%m%d')
    end

    it "uses given due and service dates" do
      bill.due_date       = Date.new(2011, 12, 10).strftime('%Y%m%d')
      bill.fch_serv_desde = Date.new(2011, 11, 01).strftime('%Y%m%d')
      bill.fch_serv_hasta = Date.new(2011, 11, 30).strftime('%Y%m%d')

      bill.setup_bill

      detail = bill.body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["FchServDesde"].should == "20111101"
      detail["FchServHasta"].should == "20111130"
      detail["FchVtoPago"].should   == "20111210"
    end
  end

  describe "#authorize" do
    Bravo::BILL_TYPE[Bravo.own_iva_cond].keys.each do |target_iva_cond|
      it "authorizes a valid bill for #{target_iva_cond.to_s}" do
        bill.net = 1000000
        bill.aliciva_id = 2
        bill.doc_num = "30710151543"
        bill.iva_cond = target_iva_cond
        bill.concepto = "Servicios"

        bill.authorized?.should  == false
        bill.authorize.should    == true
        bill.authorized?.should  == true

        response = bill.response

        response.length.should     == 28
        response.cae.length.should == 14
      end
    end
  end
end