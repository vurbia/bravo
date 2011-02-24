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

  CONCEPTO = {"01"=>"Productos", "02"=>"Servicios", "03"=>"Productos y Servicios"}

  DOCTIPO = {"80"=>"CUIT", "86"=>"CUIL", "87"=>"CDI", "89"=>"LE", "90"=>"LC", "91"=>"CI Extranjera", "92"=>"en tramite", "93"=>"Acta Nacimiento", "95"=>"CI Bs. As. RNP", "96"=>"DNI", "94"=>"Pasaporte", "99"=>"Doc. (Otro)"}

  MON_ID = [["PES", "Pesos Argentinos"],
    ["DOL", "Dolar Estadounidense"],
    ["012", "Real"],
    ["060", "Euro"],
    ["049", "Gramos de Oro Fino"]]

  ALIC_IVA = [["03", 0],
    ["04", 0.105],
    ["05", 0.21],
    ["06", 0.27]]

  BILL_TYPE = {:responsable_inscripto => {:responsable_inscripto => "01", :consumidor_final => "06"}}
end
