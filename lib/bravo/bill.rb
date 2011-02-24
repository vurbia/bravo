module Bravo
  class Bill
    attr_reader :client, :base_imp, :total
    attr_accessor :net, :doc_num, :iva_cond, :doc_type, :concept, :mon_id,
                  :due_date, :from, :to, :aliciva_id, :fch_serv_desde, :fch_serv_hasta,
                  :body

    def initialize(attrs = {})
      Bravo::AuthData.fetch
      @client = Savon::Client.new(Bravo.service_url)
      @body = {"Auth" => Bravo.auth_hash}
      self.doc_type = attrs[:doc_type]  || Bravo.default_doc_type
      self.mon_id   = attrs[:mon_id]    || Bravo.default_mon_id
      self.iva_cond = attrs[:iva_cond]
      # self.concept  = attrs[:concept]   || Bravo.default_concept

      @net          = attrs[:net]       || 0
    end

    def cbte_type
      type = Bravo::BILL_TYPE[Bravo.own_iva_cond][Bravo::COND_IVA[iva_cond]]
      raise NullOrInvalidAttribute.new, "Please choose a valid document type." if type.nil?
      type
    end

    def exchange_rate
      if mon_id == 0
        return 1
      else
        response = client.fe_param_get_cotizacion do |soap|
          soap.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
          self.body = self.body.merge({"MonId" => Bravo::MON_ID[mon_id][0]})
          soap.body = body
        end
        rate = response.to_hash[:fe_param_get_cotizacion_response][:fe_param_get_cotizacion_result][:result_get][:mon_cotiz]
        rate.to_f
      end
    end

    def total
      @total = net.zero? ? 0 : net + iva_sum
    end

    def iva_sum
      if net == 0
        @iva_sum = 0
      else
        @iva_sum = (net * Bravo::ALIC_IVA[aliciva_id][1])
      end
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
                        "Concepto"    => concept, #productos
                        "DocTipo"     => doc_type,
                        "CbteFch"     => Time.new.strftime('%Y%m%d'),
                        "ImpTotConc"  => 0.00,
                        "MonId"       => Bravo::MON_ID[mon_id],
                        "MonCotiz"    => exchange_rate,
                        "ImpOpEx"     => 0.00,
                        "ImpTrib"     => 0.00,
                        "Iva"         => {
                          "AlicIva" => {
                            "Id" => "5",
                            "BaseImp" => net,
                            "Importe" => iva_sum}}}}}}

      detail = fecaereq["FeCAEReq"]["FeDetReq"]["FECAEDetRequest"]

      detail["DocNro"]    = "#{doc_num}"
      detail["ImpNeto"]   = net.to_f
      detail["ImpIVA"]    = iva_sum
      detail["ImpTotal"]  = total
      detail["CbteDesde"] = detail["CbteHasta"] = next_bill_number

      unless concept == 0
        detail.merge!({"FchServDesde" => fch_serv_desde.nil? ? Time.new.strftime('%Y%m%d') : fch_serv_desde,
                      "FchServHasta" => fch_serv_hasta.nil?  ? Time.new.strftime('%Y%m%d') : fch_serv_hasta,
                      "FchVtoPago" => due_date.nil?          ? Time.new.strftime('%Y%m%d') : due_date})
      end

      self.body = self.body.merge(fecaereq)
    end

    def next_bill_number
      resp = client.fe_comp_ultimo_autorizado do |s|
               s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
               s.body = {"Auth" => Bravo.auth_hash,
                         "PtoVta" => Bravo.sale_point,
                         "CbteTipo" => "1"}
             end

      @nro = resp.to_hash[:fe_comp_ultimo_autorizado_response][:fe_comp_ultimo_autorizado_result][:cbte_nro]
      @nro.to_i + 1
    end

    private

    class << self
      def header(cbte_type)
        {"CantReg" => "1", #todo sacado de la factura
         "CbteTipo" => "#{cbte_type}",
         "PtoVta" => "2"}
      end
    end
  end
end
