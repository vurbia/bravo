$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bravo'
require 'rspec'
require 'vcr'
require 'simplecov'
# SimpleCov.start

begin
  require 'debugger'
rescue LoadError
  puts 'debugger not found'
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :fakeweb
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

Bravo.pkey              = 'spec/fixtures/certs/pkey'
Bravo.cert              = 'spec/fixtures/certs/cert.crt'
Bravo.cuit              = ENV['CUIT'] || '20287740027'
Bravo.sale_point        = ENV['SALE'] || '0002'
Bravo.default_concepto  = 'Productos y Servicios'
Bravo.default_documento = 'CUIT'
Bravo.default_moneda    = :peso
Bravo.own_iva_cond      = :responsable_inscripto
Bravo.logger            = { log: false, level: :debug }
Bravo.openssl_bin       = 'openssl'
Bravo::AuthData.environment = :test

# TODO: refactor into actual validations

raise(Bravo::NullOrInvalidAttribute.new, 'Please set CUIT env variable.') unless Bravo.cuit

[Bravo.pkey, Bravo.cert].each do |file|
  raise(Bravo::MissingCertificate.new, "No existe #{ file }") unless File.exist?("#{ file }")
end
