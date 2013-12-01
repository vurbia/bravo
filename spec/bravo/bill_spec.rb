# encoding: utf-8
require 'spec_helper'

describe 'Bill' do
  let(:bill) { @bill = Bravo::Bill.new(iva_condition: :consumidor_final, invoice_type: :invoice) }

  describe '.header' do
    it 'sets up the header hash' do
      @header = Bravo::Bill.header(0)
      @header.size.should == 3
      ['CantReg', 'CbteTipo', 'PtoVta'].each do |key|
        @header.has_key?(key).should == true
      end
    end
  end

  describe '.initialize' do
    it 'applies Bravos defaults' do
      bill.client.class.name.should == 'Savon::Client'

      ['Token', 'Sign', 'Cuit'].each do |key|
        bill.body['Auth'][key].should_not == nil
      end

      bill.document_type.should == Bravo.default_documento
      bill.currency.should == Bravo.default_moneda
    end
  end

  describe '#bill_type' do
    before { bill.invoice_type = :invoice }
    it 'returns the bill type for Responsable Inscripto' do
      bill.iva_condition = :responsable_inscripto

      bill.bill_type.should == '01'
    end

    it 'returns the bill type for Consumidor Final' do
      bill.iva_condition = :consumidor_final

      bill.bill_type.should == '06'
    end
  end

  describe '#iva_sum and #total' do
    it 'calculate the IVA array values' do
      bill.iva_condition  = :responsable_inscripto
      bill.currency       = :peso
      bill.net            = 100.89
      bill.aliciva_id     = 2

      bill.iva_sum.should be_within(0.005).of(21.19)
      bill.total.should be_within(0.005).of(122.08)
    end
  end

  describe '#setup_bill' do
    before do
      bill.net        = 100
      bill.aliciva_id = 2
      bill.document_number    = '30710151543'
      bill.iva_condition   = :responsable_inscripto
      bill.concept   = 'Servicios'
    end

    it 'uses today dates when due and service dates are ommitted', vcr: { cassette_name: 'setup_bill_ommitted_date' } do
      bill.setup_bill

      detail = bill.body['FeCAEReq']['FeDetReq']['FECAEDetRequest']

      detail['FchServDesde'].should == Time.new.strftime('%Y%m%d')
      detail['FchServHasta'].should == Time.new.strftime('%Y%m%d')
      detail['FchVtoPago'].should   == Time.new.strftime('%Y%m%d')
    end

    it 'uses given due and service dates', vcr: { cassette_name: 'setup_bill_given_date' } do
      bill.due_date   = Date.new(2011, 12, 10).strftime('%Y%m%d')
      bill.date_from  = Date.new(2011, 11, 01).strftime('%Y%m%d')
      bill.date_to    = Date.new(2011, 11, 30).strftime('%Y%m%d')

      bill.setup_bill

      detail = bill.body['FeCAEReq']['FeDetReq']['FECAEDetRequest']

      detail['FchServDesde'].should == '20111101'
      detail['FchServHasta'].should == '20111130'
      detail['FchVtoPago'].should   == '20111210'
    end
  end

  describe '#authorize' do
    describe 'for facturas' do
      Bravo::BILL_TYPE[Bravo.own_iva_cond].keys.each do |target_iva_cond|
        describe "issued to #{ target_iva_cond.to_s }" do
          Bravo::BILL_TYPE[Bravo.own_iva_cond][target_iva_cond].keys.each do |bill_type|
            vcr_options = { cassette_name: "#{ target_iva_cond.to_s }_and_#{ bill_type }" }
            it "authorizes bill type #{ bill_type }", vcr: vcr_options do
              bill.net          = 10000.88
              bill.aliciva_id   = 2
              bill.document_number      = '30710151543'
              bill.iva_condition     = target_iva_cond
              bill.concept     = 'Servicios'
              bill.invoice_type = bill_type

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
    end
  end
end
