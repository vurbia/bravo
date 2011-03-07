module Bravo
  class Bill
    attr_reader :client, :base_imp, :total
    attr_accessor :net, :doc_num, :iva_cond, :documento, :concepto, :moneda,
                  :due_date, :aliciva_id, :fch_serv_desde, :fch_serv_hasta,
                  :body, :response

    def initialize(attrs = {})
      Bravo::AuthData.fetch
      @client         = Savon::Client.new(Bravo.service_url)
      @body           = {"Auth" => Bravo.auth_hash}
      @net            = attrs[:net] || 0
      self.documento  = attrs[:documento] || Bravo.default_documento
      self.moneda     = attrs[:moneda]    || Bravo.default_moneda
      self.iva_cond   = attrs[:iva_cond]
      self.concepto   = attrs[:concepto]  || Bravo.default_concepto
    end

    def cbte_type
      Bravo::BILL_TYPE[Bravo.own_iva_cond][iva_cond] ||
        raise(NullOrInvalidAttribute.new, "Please choose a valid document type.")
    end

    def exchange_rate
      return 1 if moneda == :peso
      response = client.fe_param_get_cotizacion do |soap|
        soap.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
        soap.body = body.merge!({"MonId" => Bravo::MONEDAS[moneda][:codigo]})
      end
      response.to_hash[:fe_param_get_cotizacion_response][:fe_param_get_cotizacion_result][:result_get][:mon_cotiz].to_f
    end

    def total
      @total = net.zero? ? 0 : net + iva_sum
    end

    def iva_sum
      @iva_sum = net * Bravo::ALIC_IVA[aliciva_id][1]
      @iva_sum.round_up_with_precision(2)
    end

    def authorize
      setup_bill
      response = client.fecae_solicitar do |soap|
        soap.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
        soap.body = body
      end

      setup_response(response.to_hash)
      self.authorized?
    end

    def setup_bill
      today = Time.new.strftime('%Y%m%d')

      fecaereq = {"FeCAEReq" => {
                    "FeCabReq" => Bravo::Bill.header(cbte_type),
                    "FeDetReq" => {
                      "FECAEDetRequest" => {
                        "Concepto"    => Bravo::CONCEPTOS[concepto],
                        "DocTipo"     => Bravo::DOCUMENTOS[documento],
                        "CbteFch"     => today,
                        "ImpTotConc"  => 0.00,
                        "MonId"       => Bravo::MONEDAS[moneda][:codigo],
                        "MonCotiz"    => exchange_rate,
                        "ImpOpEx"     => 0.00,
                        "ImpTrib"     => 0.00,
                        "Iva"         => {
                          "AlicIva" => {
                            "Id" => "5",
                            "BaseImp" => net,
                            "Importe" => iva_sum}}}}}}

      detail = fecaereq["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["DocNro"]    = doc_num
      detail["ImpNeto"]   = net.to_f
      detail["ImpIVA"]    = iva_sum
      detail["ImpTotal"]  = total
      detail["CbteDesde"] = detail["CbteHasta"] = next_bill_number

      unless concepto == 0
        detail.merge!({"FchServDesde" => fch_serv_desde || today,
                      "FchServHasta"  => fch_serv_hasta || today,
                      "FchVtoPago"    => due_date       || today})
      end

      body.merge!(fecaereq)
    end

    def next_bill_number
      resp = client.fe_comp_ultimo_autorizado do |s|
        s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
        s.body = {"Auth" => Bravo.auth_hash, "PtoVta" => Bravo.sale_point, "CbteTipo" => "1"}
      end

      resp.to_hash[:fe_comp_ultimo_autorizado_response][:fe_comp_ultimo_autorizado_result][:cbte_nro].to_i + 1
    end

    def authorized?
      !response.nil? && response.header_result == "A" && response.detail_result == "A"
    end

    private

    class << self
      def header(cbte_type)#todo sacado de la factura
        {"CantReg" => "1", "CbteTipo" => cbte_type, "PtoVta" => "2"}
      end
    end

    def setup_response(response)
      # TODO: turn this into an all-purpose Response class

      result          = response[:fecae_solicitar_response][:fecae_solicitar_result]

      response_header = result[:fe_cab_resp]
      response_detail = result[:fe_det_resp][:fecae_det_response]

      request_header  = body["FeCAEReq"]["FeCabReq"].underscore_keys.symbolize_keys
      request_detail  = body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"].underscore_keys.symbolize_keys

      iva             = request_detail.delete(:iva)["AlicIva"].underscore_keys.symbolize_keys

      request_detail.merge!(iva)

      response_hash = {:header_result => response_header.delete(:resultado),
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
      self.response = Struct.new("Response", *keys).new(*values)
    end
  end
end
