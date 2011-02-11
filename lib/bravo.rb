require "rubygems"
require "bundler/setup"
require "bravo/version"
require "bravo/constants"
require "savon"
require "ruby-debug"
require "bravo/core_ext/float"
module Bravo

  class NullOrInvalidAttribute < StandardError; end

  autoload :Authorizer,   "bravo/authorizer"
  autoload :AuthData,     "bravo/auth_data"
  autoload :Bill,         "bravo/bill"
  autoload :Constants,    "bravo/constants"


  extend self
  attr_reader :pkey, :cert
  attr_accessor :cuit, :sale_point, :service_url, :default_doc_type,
                :default_concept, :default_mon_id, :own_iva_cond

  def pkey=(relative_path)
    @pkey = File.read(relative_path)
  end

  def cert=(relative_path)
    @cert = File.read(relative_path)
  end

  def auth_hash
    {"Token" => Bravo::TOKEN, "Sign"  => Bravo::SIGN, "Cuit"  => Bravo.cuit}
  end
end
