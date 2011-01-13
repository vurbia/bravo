module Bravo
  class Biller
    def initialize
      Bravo::AuthData.fetch
    end

    def dummy
      client = Savon::Client.new("http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL")
      # client.fecaea_solicitar do |s|
      #   s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
      #   s.body = {"Auth"      => {"Token" => TOKEN, "Sign" => SIGN, "Cuit" => CUIT.to_i},
      #             "Periodo" => "201101", "Orden" => "2"}
      # end

      # client.fecae_solicitar do |s|
      #   s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
      #   s.body = {"Auth"      => {"Token" => TOKEN, "Sign" => SIGN, "Cuit" => CUIT.to_i},
      #             "FeCAEReq"  => {"FeCabReq" => {"CantReg" => "", "CbteTipo" => "", "PtoVta" => ""},
      #                             "FeCAEDetReq" => {"Concepto" => "",
      #                                            "DocTipo" => "",
      #                                            "DocNro" => "",
      #                                            "CbteDesde" => "",
      #                                            "CbteHasta" => "",
      #                                            "CbteFch" => "",
      #                                            "ImpTotal" => "",
      #                                            "ImpTotConc" => "",
      #                                            "ImpNeto" => "",
      #                                            "ImpOpEx" => "",
      #                                            "ImpIVA" => "",
      #                                            "ImpTrib" => "",
      #                                            "MonId" => "",
      #                                            "MonCotiz" => "",
      #                                            }}}
      # end

      # client.fe_param_get_tipos_iva do |s|
      #   s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
      #   s.body = {"Auth"      => {"Token" => TOKEN, "Sign" => SIGN, "Cuit" => CUIT.to_i}}
      # end

      resp = client.fe_comp_ultimo_autorizado do |s|
               s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
               s.body = {"Auth" => {"Token" => Bravo::TOKEN, "Sign"  => Bravo::SIGN, "Cuit"  => Bravo.cuit},
                         "PtoVta" => "2", "CbteTipo" => "1"}
             end

      @nro = resp.to_hash[:fe_comp_ultimo_autorizado_response][:fe_comp_ultimo_autorizado_result][:cbte_nro]

      resp = client.fecae_solicitar do |s|
        s.namespaces["xmlns"] = "http://ar.gov.afip.dif.FEV1/"
        s.body = {"Auth" => {"Token" => Bravo::TOKEN, "Sign"  => Bravo::SIGN, "Cuit"  => Bravo.cuit},
                  "FeCAEReq"  => {"FeCabReq" => {"CantReg" => "1", #todo sacado de la factura
                                                 "CbteTipo" => "1",
                                                 "PtoVta" => "2"},
                                  "FeDetReq" => {"FECAEDetRequest" => { "Concepto" => "1", #productos
                                                                     "DocTipo" => "80",
                                                                     "DocNro" => "30710151543",
                                                                     "CbteDesde" => @nro.to_i+1,
                                                                     "CbteHasta" => @nro.to_i+1,
                                                                     "CbteFch" => Time.new.strftime('%Y%m%d'),
                                                                     "ImpTotal" => "121.00",
                                                                     "ImpTotConc" => "0.00",
                                                                     "ImpNeto" => "100.00",
                                                                     "ImpOpEx" => "0.00",
                                                                     "ImpIVA" => "21.00",
                                                                     "ImpTrib" => "0.00",
                                                                     "MonId" => "PES",
                                                                     "MonCotiz" => "1.00",
                                                                     "Iva" => { "AlicIva"  => { "Id" => "5",
                                                                                                "BaseImp" => "100",
                                                                                                "Importe" => "21"}
                                                                               }
                                                                    }
                                                  }
                                   }
                  }
      end
      resp.to_hash
    end
  end
end