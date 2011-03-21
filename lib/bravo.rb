require "bundler/setup"
require "bravo/version"
require "bravo/constants"
require "savon"
require "bravo/core_ext/float"
require "bravo/core_ext/hash"
require "bravo/core_ext/string"
module Bravo

  class NullOrInvalidAttribute < StandardError; end

  autoload :Authorizer,   "bravo/authorizer"
  autoload :AuthData,     "bravo/auth_data"
  autoload :Bill,         "bravo/bill"
  autoload :Constants,    "bravo/constants"


  extend self
  attr_accessor :cuit, :sale_point, :service_url, :default_documento, :pkey, :cert,
    :default_concepto, :default_moneda, :own_iva_cond, :verbose, :auth_url

  def auth_hash
    {"Token" => Bravo::TOKEN, "Sign"  => Bravo::SIGN, "Cuit"  => Bravo.cuit}
  end

  Savon::Request.log = false unless (Bravo.verbose == "true") || (ENV["VERBOSE"] == true)
end
