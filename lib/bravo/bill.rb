# encoding: utf-8
module Bravo
  # The main class in Bravo. Handles WSFE method interactions.
  # Subsequent implementations will be added here (maybe).
  #
  class Bill
    # Returns the Savon::Client instance in charge of the interactions
    # with WSFE API (built on init)
    #
    attr_reader :client

    attr_accessor :net, :document_number, :iva_condition, :document_type,
      :concept, :currency, :due_date, :aliciva_id, :date_from, :date_to, :body,
      :response, :invoice_type

    def initialize(attrs = {})
      opts = { wsdl: AuthData.wsfe_url }.merge! Bravo.logger_options
      @client       ||= Savon.client(opts)
      @body           = { 'Auth' => AuthData.auth_hash }
      @iva_condition  = validate_iva_condition(attrs[:iva_condition])
      @net            = attrs[:net].to_f.round(2) || 0
      @document_type  = attrs.fetch(:document_type, Bravo.default_documento)
      @currency       = attrs.fetch(:currency, Bravo.default_moneda)
      @concept        = attrs.fetch(:concept, Bravo.default_concepto)
      @invoice_type   = validate_invoice_type(attrs[:invoice_type])
    end

    # Searches the corresponding invoice type according to the combination of
    # the seller's IVA condition and the buyer's IVA condition
    # @return [String] the document type string
    #
    def bill_type
      BILL_TYPE[Bravo.own_iva_cond][iva_condition][invoice_type]
    end

    # Calculates the total field for the invoice by adding
    # net and iva_sum.
    # @return [Float] the sum of both fields, or 0 if the net is 0.
    #
    def total
      @total = net.zero? ? 0.0 : net + iva_sum
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
        soap.message body
      end

      setup_response(response.to_hash)
      authorized?
    end

    # Sets up the request body for the authorisation
    # @return [Hash] returns the request body as a hash
    #
    def setup_bill
      request = Request.new
      request.header = Bill.header(bill_type)
      request.concept = CONCEPTOS[concept]
      request.document_type = DOCUMENTOS[document_type]
      request.date = today
      request.currency_id = MONEDAS[currency][:codigo]
      request.iva_code = applicable_iva_code
      request.net_amount = net.to_f
      request.iva_amount = iva_sum
      request.document_number = document_number
      request.total = total
      request.from = request.to = Reference.next_bill_number(bill_type)

      request.date_from = date_from || today
      request.date_to   = date_to || today
      request.due_on    = due_date || today

      body.merge!(request.to_hash)
    end

    # Returns the result of the authorization operation
    # @return [Boolean] the response result
    #
    def authorized?
      response && response.header_result == 'A' && response.detail_result == 'A'
    end

    private

    class << self
      # Sets the header hash for the request
      # @return [Hash]
      #
      def header(bill_type)
        # toodo sacado de la factura
        { 'CantReg'  => '1',
          'CbteTipo' => bill_type,
          'PtoVta'   => Bravo.sale_point
        }
      end
    end

    # Response parser. Only works for the authorize method
    # @return [Struct] a struct with key-value pairs with the response values
    #
    # rubocop:disable Metrics/MethodLength
    def setup_response(response)
      # TODO: turn this into an all-purpose Response class
      result = response[:fecae_solicitar_response][:fecae_solicitar_result]

      response_header = result[:fe_cab_resp]
      response_detail = result[:fe_det_resp][:fecae_det_response]

      request_header = body['FeCAEReq']['FeCabReq'].underscore_keys.symbolize_keys
      request_detail = body['FeCAEReq']['FeDetReq']['FECAEDetRequest'].underscore_keys.symbolize_keys

      request_detail.merge!(request_detail.delete(:iva)['AlicIva'].underscore_keys.symbolize_keys)

      response_hash = { header_result: response_header.delete(:resultado),
                        authorized_on: response_header.delete(:fch_proceso),

                        detail_result: response_detail.delete(:resultado),
                        cae_due_date:  response_detail.delete(:cae_fch_vto),
                        cae:           response_detail.delete(:cae),

                        iva_id:        request_detail.delete(:id),
                        iva_importe:   request_detail.delete(:importe),
                        moneda:        request_detail.delete(:mon_id),
                        cotizacion:    request_detail.delete(:mon_cotiz),
                        iva_base_imp:  request_detail.delete(:base_imp),
                        doc_num:       request_detail.delete(:doc_nro)
                      }.merge!(request_header).merge!(request_detail)

      keys, values = response_hash.to_a.transpose

      self.response = response_klass(keys).new(*values)
    end
    # rubocop:enable Metrics/MethodLength

    def applicable_iva
      index = APPLICABLE_IVA[Bravo.own_iva_cond][iva_condition]
      ALIC_IVA[index]
    end

    def applicable_iva_code
      applicable_iva[0]
    end

    def applicable_iva_multiplier
      applicable_iva[1]
    end

    def validate_iva_condition(iva_cond)
      valid_conditions = BILL_TYPE[Bravo.own_iva_cond].keys
      if valid_conditions.include? iva_cond
        iva_cond
      else
        raise(NullOrInvalidAttribute.new,
          "El valor de iva_condition debe estar incluído en #{ valid_conditions }")
      end
    end

    def validate_invoice_type(type)
      return type if BILL_TYPE_A.keys.include? type

      raise(NullOrInvalidAttribute.new, "invoice_type debe estar incluido en \
            #{ Bravo::BILL_TYPE_A.keys }")
    end

    def today
      Time.new.strftime('%Y%m%d')
    end

    def response_klass(keys)
      Struct.new('Response', *keys) unless Struct.constants.include?(:Response)
      Struct::Response
    end
  end
end
