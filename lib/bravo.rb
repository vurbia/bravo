# encoding: utf-8
require 'bundler/setup'
require 'bravo/version'
require 'bravo/constants'
require 'savon'
require 'bravo/core_ext/hash'
require 'bravo/core_ext/string'

module Bravo

  # Exception Class for missing or invalid attributes
  #
  class NullOrInvalidAttribute < StandardError; end

  # Exception Class for missing or invalid certifficate
  #
  class MissingCertificate < StandardError; end


  # This class handles the logging options
  #
  class Logger < Struct.new(:log, :pretty_xml, :level)
    # @param opts [Hash] receives a hash with keys `log`, `pretty_xml` (both
    # boolean) or the desired log level as `level`

    def initialize(opts = {})
      self.log = opts[:log] || false
      self.pretty_xml = opts[:pretty_xml] || self.log
      self.level = opts[:level] || :debug
    end

    # @return [Hash] returns a hash with the proper logging optios for Savon.
    def logger_options
      { log: self.log, pretty_print_xml: self.pretty_xml, log_level: self.level }
    end
  end

  autoload :Authorizer,   'bravo/authorizer'
  autoload :AuthData,     'bravo/auth_data'
  autoload :Bill,         'bravo/bill'
  autoload :Constants,    'bravo/constants'
  autoload :Wsaa,         'bravo/wsaa'
  autoload :Reference,    'bravo/reference'

  extend self

  attr_accessor :cuit, :sale_point, :default_documento, :pkey, :cert,
                :default_concepto, :default_moneda, :own_iva_cond,
                :openssl_bin

  class << self
    # Receiver of the logging configuration options.
    # @param opts [Hash] pass a hash with `log`, `pretty_xml` and `level` keys to set
    # them.
    def logger=(opts)
      @logger ||= Logger.new(opts)
    end

    # Sets the logger options to the default values or returns the previously set
    # logger options
    # @return [Logger]
    def logger
      @logger ||= Logger.new
    end

    # Returs the formatted logger options to be used by Savon.
    def logger_options
      logger.logger_options
    end

    def own_iva_cond=(iva_cond_symbol)
      if Bravo::BILL_TYPE.has_key?(iva_cond_symbol)
        @own_iva_cond = iva_cond_symbol
      else
        raise(NullOrInvalidAttribute.new, "El valor de  own_iva_cond: (#{ iva_cond_symbol }) es inválido.")
      end
    end
  end
end
