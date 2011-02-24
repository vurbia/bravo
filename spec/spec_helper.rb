$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bravo'
require 'rspec'

class SpecHelper
  include Savon::Logger
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Savon::Request.log = false unless ENV["VERBOSE"] == "true"

Bravo.pkey = "spec/fixtures/pkey"
Bravo.cert = "spec/fixtures/cert.crt"
Bravo.cuit = "30711034389"
Bravo.sale_point = "0002"
Bravo.service_url = "http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"
Bravo.default_concepto = "Productos y Servicios"
Bravo.default_documento = "CUIT"
Bravo.default_moneda = :peso
Bravo.own_iva_cond = :responsable_inscripto
