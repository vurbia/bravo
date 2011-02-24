# encoding: utf-8
module Bravo
  CBTE_TIPO = {
    "01"=>"Factura A",
    "02"=>"Nota de Débito A",
    "03"=>"Nota de Crédito A",
    "04"=>"Recibos A",
    "05"=>"Notas de Venta al contado A",
    "06"=>"Factura B",
    "07"=>"Nota de Debito B",
    "08"=>"Nota de Credito B",
    "09"=>"Recibos B",
    "10"=>"Notas de Venta al contado B",
    "34"=>"Cbtes. A del Anexo I, Apartado A,inc.f),R.G.Nro. 1415",
    "35"=>"Cbtes. B del Anexo I,Apartado A,inc. f),R.G. Nro. 1415",
    "39"=>"Otros comprobantes A que cumplan con R.G.Nro. 1415",
    "40"=>"Otros comprobantes B que cumplan con R.G.Nro. 1415",
    "60"=>"Cta de Vta y Liquido prod. A",
    "61"=>"Cta de Vta y Liquido prod. B",
    "63"=>"Liquidacion A",
    "64"=>"Liquidacion B"
  }

  CONCEPTOS = {"Productos"=>"01", "Servicios"=>"02", "Productos y Servicios"=>"03"}

  DOCUMENTOS = {"CUIT"=>"80", "CUIL"=>"86", "CDI"=>"87", "LE"=>"89", "LC"=>"90", "CI Extranjera"=>"91", "en tramite"=>"92", "Acta Nacimiento"=>"93", "CI Bs. As. RNP"=>"95", "DNI"=>"96", "Pasaporte"=>"94", "Doc. (Otro)"=>"99"}

  MONEDAS = {
    :peso  => {:codigo => "PES", :nombre =>"Pesos Argentinos"},
    :dolar => {:codigo => "DOL", :nombre =>"Dolar Estadounidense"},
    :real  => {:codigo => "012", :nombre =>"Real"},
    :euro  => {:codigo => "060", :nombre =>"Euro"},
    :oro   => {:codigo => "049", :nombre =>"Gramos de Oro Fino"}
  }

  ALIC_IVA = [["03", 0],
    ["04", 0.105],
    ["05", 0.21],
    ["06", 0.27]]

  BILL_TYPE = {:responsable_inscripto => {:responsable_inscripto => "01", :consumidor_final => "06"}}
end
