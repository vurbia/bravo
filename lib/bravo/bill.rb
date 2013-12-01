# encoding: utf-8
module Bravo
  # The main class in Bravo. Handles WSFE method interactions.
  # Subsequent implementations will be added here (maybe).
  #
  class Bill
    # Returns the Savon::Client instance in charge of the interactions with WSFE API.
    # (built on init)
    #
    attr_reader :client

    attr_accessor :net, :document_number, :iva_condition, :document_type, :concept,
      :currency, :due_date, :aliciva_id, :date_from, :date_to, :body, :response,
      :invoice_type

    def initialize(attrs = {})
      opts = { wsdl: Bravo::AuthData.wsfe_url }.merge! Bravo.logger_options
      @client       ||= Savon.client(opts)
      @body           = { 'Auth' => Bravo::AuthData.auth_hash }
      @iva_condition  = validate_iva_condition(attrs[:iva_condition])
      @net            = attrs[:net]           || 0
      @document_type  = attrs[:document_type] || Bravo.default_documento
      @currency       = attrs[:currency]      || Bravo.default_moneda
      @concept        = attrs[:concept]       || Bravo.default_concepto
      @invoice_type   = validate_invoice_type(attrs[:invoice_type])
    end

    # Searches the corresponding invoice type according to the combination of
    # the seller's IVA condition and the buyer's IVA condition
    # @return [String] the document type string
    #
    def bill_type
      Bravo::BILL_TYPE[Bravo.own_iva_cond][iva_condition][invoice_type]
    end

    # Calculates the total field for the invoice by adding
    # net and iva_sum.
    # @return [Float] the sum of both fields, or 0 if the net is 0.
    #
    def total
      @total = net.zero? ? 0 : net + iva_sum
    end

    # Calculates the corresponding iva sum.
    # This is performed by multiplying the net by the tax value
    # @return [Float] the iva sum
    #
    # TODO: fix this
    #
    def iva_sum
      @iva_sum = net * applicable_iva_multiplier
      @iva_sum.round(2)
    end

    # Files the authorization request to AFIP
    # @return [Boolean] wether the request succeeded or not
    #
    def authorize
      setup_bill
      response = client.call(:fecae_solicitar) do |soap|
        # soap.namespaces['xmlns'] = 'http://ar.gov.afip.dif.FEV1/'
        soap.message body
      end

      setup_response(response.to_hash)
      self.authorized?
    end

    # Sets up the request body for the authorisation
    # @return [Hash] returns the request body as a hash
    #
    def setup_bill
      today = Time.new.strftime('%Y%m%d')

      fecaereq = { 'FeCAEReq' => {
                    'FeCabReq' => Bravo::Bill.header(bill_type),
                    'FeDetReq' => {
                      'FECAEDetRequest' => {
                        'Concepto'    => Bravo::CONCEPTOS[concept],
                        'DocTipo'     => Bravo::DOCUMENTOS[document_type],
                        'CbteFch'     => today,
                        'ImpTotConc'  => 0.00,
                        'MonId'       => Bravo::MONEDAS[currency][:codigo],
                        'MonCotiz'    => 1,
                        'ImpOpEx'     => 0.00,
                        'ImpTrib'     => 0.00,
                        'Iva'         => {
                          'AlicIva' => {
                            'Id' => applicable_iva_code,
                            'BaseImp' => net.round(2),
                            'Importe' => iva_sum } } } } } }

      detail = fecaereq['FeCAEReq']['FeDetReq']['FECAEDetRequest']

      detail['DocNro']    = document_number
      detail['ImpNeto']   = net.to_f
      detail['ImpIVA']    = iva_sum
      detail['ImpTotal']  = total
      detail['CbteDesde'] = detail['CbteHasta'] = Bravo::Reference.next_bill_number(bill_type)

      unless concept == 0
        detail.merge!({ 'FchServDesde'  => date_from  || today,
                        'FchServHasta'  => date_to    || today,
                        'FchVtoPago'    => due_date   || today })
      end

      body.merge!(fecaereq)
    end

    # Returns the result of the authorization operation
    # @return [Boolean] the response result
    #
    def authorized?
      !response.nil? && response.header_result == 'A' && response.detail_result == 'A'
    end

    private

    class << self
      # Sets the header hash for the request
      # @return [Hash]
      #
      def header(bill_type)
        # todo sacado de la factura
        { 'CantReg' => '1', 'CbteTipo' => bill_type, 'PtoVta' => Bravo.sale_point }
      end
    end

    # Response parser. Only works for the authorize method
    # @return [Struct] a struct with key-value pairs with the response values
    #
    def setup_response(response)
      # TODO: turn this into an all-purpose Response class

      result          = response[:fecae_solicitar_response][:fecae_solicitar_result]

      response_header = result[:fe_cab_resp]
      response_detail = result[:fe_det_resp][:fecae_det_response]

      request_header  = body['FeCAEReq']['FeCabReq'].underscore_keys.symbolize_keys
      request_detail  = body['FeCAEReq']['FeDetReq']['FECAEDetRequest'].underscore_keys.symbolize_keys

      iva             = request_detail.delete(:iva)['AlicIva'].underscore_keys.symbolize_keys

      request_detail.merge!(iva)

      response_hash = { :header_result => response_header.delete(:resultado),
                        :authorized_on => response_header.delete(:fch_proceso),
                        :detail_result => response_detail.delete(:resultado),
                        :cae_due_date  => response_detail.delete(:cae_fch_vto),
                        :cae           => response_detail.delete(:cae),
                        :iva_id        => request_detail.delete(:id),
                        :iva_importe   => request_detail.delete(:importe),
                        :moneda        => request_detail.delete(:mon_id),
                        :cotizacion    => request_detail.delete(:mon_cotiz),
                        :iva_base_imp  => request_detail.delete(:base_imp),
                        :doc_num       => request_detail.delete(:doc_nro)
                        }.merge!(request_header).merge!(request_detail)

      keys, values  = response_hash.to_a.transpose

      self.response = (defined?(Struct::Response) ? Struct::Response : Struct.new('Response', *keys)).new(*values)
    end

    def applicable_iva
      index = Bravo::APPLICABLE_IVA[Bravo.own_iva_cond][iva_condition]
      Bravo::ALIC_IVA[index]
    end

    def applicable_iva_code
      applicable_iva[0]
    end

    def applicable_iva_multiplier
      applicable_iva[1]
    end

    def validate_iva_condition(iva_cond)
      valid_conditions = Bravo::BILL_TYPE[Bravo.own_iva_cond].keys
      if valid_conditions.include? iva_cond
        iva_cond
      else
        raise(NullOrInvalidAttribute.new,
              "El valor de iva_condition debe estar incluído en #{ valid_conditions }")
      end
    end

    def validate_invoice_type(type)
      if Bravo::BILL_TYPE_A.keys.include? type
        type
      else
        raise(NullOrInvalidAttribute.new, "invoice_type debe estar incluido en \
            #{ Bravo::BILL_TYPE_A.keys }")
      end
    end
  end
end
