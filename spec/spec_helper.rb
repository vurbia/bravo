$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bravo'
require 'rspec'

class SpecHelper
  include Savon::Logger
  log = false
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end

Bravo.pkey = "spec/fixtures/pkey"
Bravo.cert = "spec/fixtures/cert.crt"
Bravo.cuit = "30711034389"
Bravo.sale_point = "0002"
Bravo.service_url = "http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"
Bravo.default_concept = 2  # prod y ss
Bravo.default_doc_type = 0 # cuit
Bravo.default_mon_id = 0   # pesos
Bravo.own_iva_cond = :responsable_inscripto
