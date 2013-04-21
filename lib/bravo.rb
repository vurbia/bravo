require 'bundler/setup'
require 'bravo/version'
require 'bravo/constants'
require 'savon'
require 'bravo/core_ext/float'
require 'bravo/core_ext/hash'
require 'bravo/core_ext/string'

module Bravo

  # Exception Class for missing or invalid attributes
  #
  class NullOrInvalidAttribute < StandardError; end

  # Exception Clas for missing or invalid certifficate
  #
  class MissingCertificate < StandardError; end

  autoload :Authorizer,   'bravo/authorizer'
  autoload :AuthData,     'bravo/auth_data'
  autoload :Bill,         'bravo/bill'
  autoload :Constants,    'bravo/constants'
  autoload :Wsaa,         'bravo/wsaa'
  autoload :Reference,    'bravo/reference'

  extend self

  attr_accessor :cuit, :sale_point, :default_documento, :pkey, :cert,
                :default_concepto, :default_moneda, :own_iva_cond,
                :verbose, :openssl_bin

end