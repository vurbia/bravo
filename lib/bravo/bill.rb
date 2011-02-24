module Bravo
  class Bill
    attr_reader :client, :base_imp, :total
    attr_accessor :net, :doc_num, :iva_cond, :documento, :concepto, :moneda,
                  :due_date, :from, :to, :aliciva_id, :fch_serv_desde, :fch_serv_hasta,
                  :body

    def initialize(attrs = {})
      Bravo::AuthData.fetch
      @client = Savon::Client.new(Bravo.service_url)
      @body = {"Auth" => Bravo.auth_hash}
      self.documento  = attrs[:documento]  || Bravo.default_documento
      self.moneda     = attrs[:moneda]    || Bravo.default_moneda
      self.iva_cond   = attrs[:iva_cond]
      self.concepto   = attrs[:concepto] || Bravo.default_concepto


      @net          = attrs[:net]       || 0
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

      response = response.to_hash

      detail_response = response[:fecae_solicitar_response][:fecae_solicitar_result][:fe_det_resp][:fecae_det_response]
      detail = body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["Resultado"] = detail_response[:resultado]
      detail["CaeFechVto"] = detail_response[:cae_fch_vto]
      detail["CAE"] = detail_response[:cae]

      body["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"] = detail

      header_response = response[:fecae_solicitar_response][:fecae_solicitar_result][:fe_cab_resp]
      header = body["FeCAEReq"]["FeCabReq"]

      header["Resultado"] = header_response[:resultado]
      header["Reproceso"] = header_response[:reproceso]
      header["FchProceso"] = header_response[:fch_proceso]

      body["FeCAEReq"]["FeCabReq"] = header
      body.to_hash
    end

    def setup_bill
      fecaereq = {"FeCAEReq" => {
                    "FeCabReq" => Bravo::Bill.header(cbte_type),
                    "FeDetReq" => {
                      "FECAEDetRequest" => {
                        "Concepto"    => Bravo::CONCEPTOS[concepto],
                        "DocTipo"     => Bravo::DOCUMENTOS[documento],
                        "CbteFch"     => Time.new.strftime('%Y%m%d'),
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
        time = Time.new.strftime('%Y%m%d')
        detail.merge!({"FchServDesde" => fch_serv_desde || time,
                      "FchServHasta"  => fch_serv_hasta || time,
                      "FchVtoPago"    => due_date       || time})
      end

      body.merge!(fecaereq)
    end

    def next_bill_number
      resp = client.fe_comp_ultimo_autorizado do |s|
        s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
        s.body = {"Auth" => Bravo.auth_hash,
          "PtoVta" => Bravo.sale_point,
          "CbteTipo" => "1"}
      end

      resp.to_hash[:fe_comp_ultimo_autorizado_response][:fe_comp_ultimo_autorizado_result][:cbte_nro].to_i + 1
    end

    private

    class << self
      def header(cbte_type)
        {"CantReg" => "1", #todo sacado de la factura
         "CbteTipo" => cbte_type,
         "PtoVta" => "2"}
      end
    end
  end
end
