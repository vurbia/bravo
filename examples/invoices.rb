require 'bravo'
require 'pp'

# Set up Bravo defaults/config.
Bravo.pkey              = 'spec/fixtures/certs/pkey'
Bravo.cert              = 'spec/fixtures/certs/cert.crt'
Bravo.cuit              = '20287740027'
Bravo.sale_point        = '0002'
Bravo.default_concepto  = 'Productos y Servicios'
Bravo.default_moneda    = :peso
Bravo.own_iva_cond      = :responsable_inscripto
Bravo.openssl_bin       = '/usr/local/Cellar/openssl/1.0.1e/bin/openssl'
Bravo::AuthData.environment         = :test

# Let's issue a Factura for 1200 ARS to a Responsable Inscripto
bill_a = Bravo::Bill.new(iva_condition: :responsable_inscripto, net: 1200, invoice_type: :invoice)
bill_a.document_number      = '30710151543'
bill_a.document_type        = 'CUIT'
bill_a.authorize

puts "Let's issue a Factura for 1200 ARS to a Responsable Inscripto"
puts "Authorization result = #{ bill_a.authorized? }"
puts "Authorization response."
pp bill_a.response

# Let's issue a Factura for 100 ARS to a Consumidor Final
bill_b = Bravo::Bill.new(iva_condition: :consumidor_final, net: 100, invoice_type: :invoice)
bill_b.document_number = '28774003'
bill_b.document_type = 'DNI'
bill_b.authorize

puts "Let's issue a Factura for 100 ARS to a Consumidor Final"
puts "Authorization result = #{ bill_b.authorized? }"
puts "Authorization response."
pp bill_b.response
