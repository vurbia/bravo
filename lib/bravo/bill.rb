module Bravo
  # The main class in Bravo. Handles WSFE method interactions.
  # Subsequent implementations will be added here (maybe).
  #
  class Bill
    # Returns the Savon::Client instance in charge of the interactions with WSFE API.
    # (built on init)
    #
    attr_reader :client

    attr_accessor :net, :doc_num, :iva_cond, :documento, :concepto, :moneda,
                  :due_date, :aliciva_id, :fch_serv_desde, :fch_serv_hasta,
                  :body, :response

    def initialize(attrs = {})
      Bravo::AuthData.fetch
      @client         = Savon::Client.new(Bravo.service_url)
      @body           = { "Auth" => Bravo.auth_hash }
      @net            = attrs[:net] || 0
      self.documento  = attrs[:documento] || Bravo.default_documento
      self.moneda     = attrs[:moneda]    || Bravo.default_moneda
      self.iva_cond   = attrs[:iva_cond]
      self.concepto   = attrs[:concepto]  || Bravo.default_concepto
    end

    # Searches the corresponding invoice type according to the combination of
    # the seller's IVA condition and the buyer's IVA condition
    # @return [String] the document type string
    #
    def cbte_type
      Bravo::BILL_TYPE[Bravo.own_iva_cond][iva_cond] ||
        raise(NullOrInvalidAttribute.new, "Please choose a valid document type.")
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
      @iva_sum = net * Bravo::ALIC_IVA[aliciva_id][1]
      @iva_sum.round_up_with_precision(2)
    end

    # Files the authorization request to AFIP
    # @return [Boolean] wether the request succeeded or not
    #
    def authorize
      setup_bill
      response = client.fecae_solicitar do |soap|
        soap.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
        soap.body = body
      end

      setup_response(response.to_hash)
      self.authorized?
    end

    # Sets up the request body for the authorisation
    # @return [Hash] returns the request body as a hash
    #
    def setup_bill
      today = Time.new.strftime('%Y%m%d')

      fecaereq = { "FeCAEReq" => {
                    "FeCabReq" => Bravo::Bill.header(cbte_type),
                    "FeDetReq" => {
                      "FECAEDetRequest" => {
                        "Concepto"    => Bravo::CONCEPTOS[concepto],
                        "DocTipo"     => Bravo::DOCUMENTOS[documento],
                        "CbteFch"     => today,
                        "ImpTotConc"  => 0.00,
                        "MonId"       => Bravo::MONEDAS[moneda][:codigo],
                        "MonCotiz"    => 1,
                        "ImpOpEx"     => 0.00,
                        "ImpTrib"     => 0.00,
                        "Iva"         => {
                          "AlicIva" => {
                            "Id" => "5",
                            "BaseImp" => net,
                            "Importe" => iva_sum } } } } } }

      detail = fecaereq["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["DocNro"]    = doc_num
      detail["ImpNeto"]   = net.to_f
      detail["ImpIVA"]    = iva_sum
      detail["ImpTotal"]  = total
      detail["CbteDesde"] = detail["CbteHasta"] = next_bill_number

      unless concepto == 0
        detail.merge!({ "FchServDesde"  => fch_serv_desde || today,
                        "FchServHasta"  => fch_serv_hasta || today,
                        "FchVtoPago"    => due_date       || today })
      end

      body.merge!(fecaereq)
    end

    # Fetches the number for the next bill to be issued
    # @return [Integer] the number for the next bill
    #
    def next_bill_number
      resp = client.fe_comp_ultimo_autorizado do |s|
        s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
        s.body = { "Auth" => Bravo.auth_hash, "PtoVta" => Bravo.sale_point, "CbteTipo" => cbte_type }
      end

      resp.to_hash[:fe_comp_ultimo_autorizado_response][:fe_comp_ultimo_autorizado_result][:cbte_nro].to_i + 1
    end

    # Returns the result of the authorization operation
    # @return [Boolean] the response result
    #
    def authorized?
      !response.nil? && response.header_result == "A" && response.detail_result == "A"
    end

    private

    class << self
      # Sets the header hash for the request
      # @return [Hash]
      #
      def header(cbte_type)
        # todo sacado de la factura
        { "CantReg" => "1", "CbteTipo" => cbte_type, "PtoVta" => Bravo.sale_point }
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

      request_header  = body["FeCAEReq"]["FeCabReq"].underscore_keys.symbolize_keys
      request_detail  = body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"].underscore_keys.symbolize_keys

      iva             = request_detail.delete(:iva)["AlicIva"].underscore_keys.symbolize_keys

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
      self.response = (defined?(Struct::Response) ? Struct::Response : Struct.new("Response", *keys)).new(*values)
    end
  end
end
