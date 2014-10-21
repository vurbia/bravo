# encoding: utf-8
require 'spec_helper'

describe 'Bill' do
  let(:bill) { @bill = Bravo::Bill.new(iva_condition: :consumidor_final, invoice_type: :invoice) }

  describe '.header' do
    it 'sets up the header hash' do
      @header = Bravo::Bill.header(0)
      expect(@header.size).to be 3
      %w[CantReg CbteTipo PtoVta].each do |key|
        expect(@header.key?(key)).to be_true
      end
    end
  end

  describe '.initialize' do
    it 'applies Bravos defaults' do
      expect(bill.client).to be_a Savon::Client

      %w[Token Sign Cuit].each do |key|
        expect(bill.body['Auth'].fetch(key, nil)).not_to be_nil
      end

      expect(bill.document_type).to be Bravo.default_documento
      expect(bill.currency).to be Bravo.default_moneda
    end
  end

  describe '#bill_type' do
    before { bill.invoice_type = :invoice }
    it 'returns the bill type for Responsable Inscripto' do
      bill.iva_condition = :responsable_inscripto

      expect(bill.bill_type).to eq '01'
    end

    it 'returns the bill type for Consumidor Final' do
      bill.iva_condition = :consumidor_final

      expect(bill.bill_type).to eq '06'
    end
  end

  describe '#iva_sum and #total' do
    it 'calculate the IVA array values' do
      bill.iva_condition  = :responsable_inscripto
      bill.currency       = :peso
      bill.net            = 100.89
      bill.aliciva_id     = 2

      expect(bill.iva_sum).to be_within(0.005).of(21.19)
      expect(bill.total).to be_within(0.005).of(122.08)
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

    it 'uses today dates when due and service dates are null',
      vcr: { cassette_name: 'setup_bill_ommitted_date' } do
      bill.setup_bill

      detail = bill.body['FeCAEReq']['FeDetReq']['FECAEDetRequest']

      expect(detail['FchServDesde']).to eq Time.new.strftime('%Y%m%d')
      expect(detail['FchServHasta']).to eq Time.new.strftime('%Y%m%d')
      expect(detail['FchVtoPago']).to   eq Time.new.strftime('%Y%m%d')
    end

    it 'uses given due and service dates', vcr: { cassette_name: 'setup_bill_given_date' } do
      bill.due_date   = Date.new(2011, 12, 10).strftime('%Y%m%d')
      bill.date_from  = Date.new(2011, 11, 01).strftime('%Y%m%d')
      bill.date_to    = Date.new(2011, 11, 30).strftime('%Y%m%d')

      bill.setup_bill

      detail = bill.body['FeCAEReq']['FeDetReq']['FECAEDetRequest']

      expect(detail['FchServDesde']).to eq '20111101'
      expect(detail['FchServHasta']).to eq '20111130'
      expect(detail['FchVtoPago']).to   eq '20111210'
    end
  end

  describe '#authorize' do
    describe 'for facturas' do
      Bravo::BILL_TYPE[Bravo.own_iva_cond].keys.each do |target_iva_cond|
        describe "issued to #{ target_iva_cond }" do
          Bravo::BILL_TYPE[Bravo.own_iva_cond][target_iva_cond].keys.each do |bill_type|
            vcr_options = { cassette_name: "#{ target_iva_cond }_and_#{ bill_type }" }
            it "authorizes bill type #{ bill_type }", vcr: vcr_options do
              bill.net = 10_000.88
              bill.aliciva_id = 2
              bill.document_number = '30710151543'
              bill.iva_condition = target_iva_cond
              bill.concept = 'Servicios'
              bill.invoice_type = bill_type

              expect(bill.authorized?).to  be_false

              expect(bill.authorize).to   be_true
              expect(bill.authorized?).to  be_true

              response = bill.response

              expect(response.length).to     eql 28
              expect(response.cae.length).to eql 14
            end
          end
        end
      end
    end
  end
end
