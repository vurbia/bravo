# encoding: utf-8
# Here we define Hashes
#
module Bravo
  # This constant contains the invoice types mappings between codes and names
  # used by WSFE.
  CBTE_TIPO = {
    '01'=>'Factura A',
    '02'=>'Nota de Débito A',
    '03'=>'Nota de Crédito A',
    '04'=>'Recibos A',
    '05'=>'Notas de Venta al contado A',
    '06'=>'Factura B',
    '07'=>'Nota de Debito B',
    '08'=>'Nota de Credito B',
    '09'=>'Recibos B',
    '10'=>'Notas de Venta al contado B',
    '34'=>'Cbtes. A del Anexo I, Apartado A,inc.f),R.G.Nro. 1415',
    '35'=>'Cbtes. B del Anexo I,Apartado A,inc. f),R.G. Nro. 1415',
    '39'=>'Otros comprobantes A que cumplan con R.G.Nro. 1415',
    '40'=>'Otros comprobantes B que cumplan con R.G.Nro. 1415',
    '60'=>'Cta de Vta y Liquido prod. A',
    '61'=>'Cta de Vta y Liquido prod. B',
    '63'=>'Liquidacion A',
    '64'=>'Liquidacion B'
  }

  # Name to code mapping for Sale types.
  #
  CONCEPTOS = { 'Productos'=>'01', 'Servicios'=>'02', 'Productos y Servicios'=>'03' }

  # Name to code mapping for types of documents.
  #
  DOCUMENTOS = {
    'CUIT'=>'80',
    'CUIL'=>'86',
    'CDI'=>'87',
    'LE'=>'89',
    'LC'=>'90',
    'CI Extranjera'=>'91',
    'en tramite'=>'92',
    'Acta Nacimiento'=>'93',
    'CI Bs. As. RNP'=>'95',
    'DNI'=>'96',
    'Pasaporte'=>'94',
    'Doc. (Otro)'=>'99' }

  # Currency code and names hash identified by a symbol
  #
  MONEDAS = {
    :peso  => { :codigo => 'PES', :nombre =>'Pesos Argentinos' },
    :dolar => { :codigo => 'DOL', :nombre =>'Dolar Estadounidense' },
    :real  => { :codigo => '012', :nombre =>'Real' },
    :euro  => { :codigo => '060', :nombre =>'Euro' },
    :oro   => { :codigo => '049', :nombre =>'Gramos de Oro Fino' } }


  # Tax percentage and codes according to each iva combination
  #
  ALIC_IVA = [['03', 0], ['04', 0.105], ['05', 0.21], ['06', 0.27]]



  # This hash keeps the codes for A document types by operation
  #
  BILL_TYPE_A = {
    :invoice => '01',
    :debit   => '02',
    :credit  => '03' }

  # This hash keeps the codes for A document types by operation
  #
  BILL_TYPE_B = {
    :invoice => '06',
    :debit   => '07',
    :credit  => '08' }

  # This hash keeps the different buyer and invoice type mapping corresponding to
  # the seller's iva condition and invoice kind.
  # Usage:
  #   `BILL_TYPE[seller_iva_cond][buyer_iva_cond][invoice_type]` #=> invoice type as string
  #   `BILL_TYPE[:responsable_inscripto][:responsable_inscripto][:invoice]` #=> '01'
  #
  BILL_TYPE = {
    :responsable_inscripto => {
      :responsable_inscripto    => BILL_TYPE_A,
      :consumidor_final         => BILL_TYPE_B,
      :exento                   => BILL_TYPE_B,
      :responsable_monotributo  => BILL_TYPE_B } }

  # This hash keeps the set of urls for wsaa and wsfe for production and testing envs
  #
  URLS = {
    :test => { :wsaa => 'https://wsaahomo.afip.gov.ar/ws/services/LoginCms',
               :wsfe => 'https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL' },

    :production => { :wsaa => 'https://wsaa.afip.gov.ar/ws/services/LoginCms',
                     :wsfe => 'https://servicios1.afip.gov.ar/wsfev1/service.asmx' } }
end